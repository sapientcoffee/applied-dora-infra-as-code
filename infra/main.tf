

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
  source                    = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster"
  project_id                = var.project_id
  name                      = "${var.deployment_name}-cluster"
  regional                  = false
  region                    = var.region
  zones                     = [var.zone]
  network                   = google_compute_network.gke-network.name
  subnetwork                = google_compute_subnetwork.cluster-subnet.name
  ip_range_pods             = ""
  ip_range_services         = ""
  config_connector          = true
  create_service_account    = false
  remove_default_node_pool  = true
  

  node_pools = [
    {
      name         = "${var.deployment_name}-node-pool"
      min_count          = 1
      max_count          = 1
      initial_node_count = 1
      machine_type = "n1-standard-1"
      auto_repair        = true
      auto_upgrade       = false
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
