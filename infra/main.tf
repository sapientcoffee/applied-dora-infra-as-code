terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.77.0"
    }
  }
}

data "google_project" "project" {
  project_id = var.project_id
}

data "google_client_config" "default" {}

provider "google" {
  region  = var.region
  project = var.project_id
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "project_services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  project_id                  = var.project_id
  disable_services_on_destroy = false
  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "container.googleapis.com"
  ]
}

module "gke" {
  source                 = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster"
  project_id             = var.project_id
  name                   = "${var.deployment_name}-cluster"
  regional               = false
  region                 = var.region
  zones                  = [var.zone]
  network                = "default"
  subnetwork             = "default"
  ip_range_pods          = ""
  ip_range_services      = ""
  config_connector       = true
  create_service_account = false

  node_pools = [
    {
      name         = "${var.deployment_name}-node-pool"
      node_count   = 3
      machine_type = "e2-standard-2"
    }
  ]

  node_pools_oauth_scopes = {
    all = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  depends_on = [
    module.project_services
  ]
}

module "workload_identity" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  project_id   = var.project_id
  cluster_name = module.gke.name
  location     = module.gke.location
  name         = "${var.deployment_name}-wi-sa"
  namespace    = "default"

  roles = [
    "roles/cloudtrace.agent",
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
    "roles/stackdriver.resourceMetadata.writer"
  ]
}

module "service_account" {
  source        = "terraform-google-modules/service-accounts/google"
  project_id    = var.project_id
  names         = ["${var.deployment_name}-kcc-sa"]
  project_roles = ["${var.project_id}=>roles/editor"]

}

module "service_account_binding" {
  source           = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  project          = var.project_id
  service_accounts = ["${module.service_account.email}"]
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${var.project_id}.svc.id.goog[cnrm-system/cnrm-controller-manager]"
    ]
  }

  depends_on = [
    module.workload_identity,
  ]
}

resource "null_resource" "configconnector_resources" {
  provisioner "local-exec" {
    command = "sed -i '' 's/GSA_EMAIL/${module.service_account.email}/' configconnector.yaml"
  }

  provisioner "local-exec" {
    command = "sed -i '' 's/PROJECT_ID/${var.project_id}/' namespace.yaml"
  }
}