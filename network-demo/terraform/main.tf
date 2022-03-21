resource "google_compute_network" "iac-virt-net" {
  name = "${var.prefix}-virt-net"
  project = "${var.project}"
  auto_create_subnetworks = false
  mtu                     = 1460
}

// Flat White Subnet
resource "google_compute_subnetwork" "flat-white" {
  name          = "${var.prefix}-flat-white"
  project       = "${var.project}"
  region        = "${var.region}"
  ip_cidr_range = "192.168.16.0/22"
  network       = "${google_compute_network.iac-virt-net.self_link}"
}

// Espresso Subnet
resource "google_compute_subnetwork" "subnet-espresso" {
  name          = "${var.prefix}-espresso"
  region        = "${var.region}"
  project       = "${var.project}"
  ip_cidr_range = "192.168.101.0/26"
  network       = "${google_compute_network.iac-virt-net.self_link}"

  // Add some logging/IPFix
  # log_config {
  #   aggregation_interval = "INTERVAL_10_MIN"
  #   flow_sampling        = 0.5
  #   metadata             = "INCLUDE_ALL_METADATA"
  # }
}

// Make a change without PR
# resource "google_compute_firewall" "allow-something" {
#   name    = "${var.prefix}-allow-something"
#   network = "${google_compute_network.iac-virt-net.name}"
#   //project = "${var.project}"
#   description = "Creates firewall rule targeting tagged instances"

#   allow {
#     protocol = "icmp"
#   }
#   allow {
#     protocol = "tcp"
#     ports    = ["80", "8080", "1000-2000"]
#   }
#   source_tags = ["web"]
# }


// Do this one with a PR
# resource "google_compute_firewall" "allow-ssh" {
#   name    = "${var.prefix}-allow-ssh"
#   network = "${google_compute_network.iac-virt-net.name}"
#   //project = "${var.project}"

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }

#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["allow-ssh"]
# }





# This queries GCP for the latest Kubernetes engine version.
# data "google_container_engine_versions" "versions" {
#   location = var.region
# }

# # This creates a new Google Kubernetes Engine (GKE) cluster inside our project.
# # This operation can take a few minutes to complete, but Terraform will show
# # output and updates as the creation progresses.
# resource "google_container_cluster" "iac-cluster" {
#   name     = "iac-cluster"
#   location = var.region

#   initial_node_count = 1

#   min_master_version = data.google_container_engine_versions.versions.latest_master_version
#   node_version       = data.google_container_engine_versions.versions.latest_node_version

#   node_config {
#     machine_type = var.instance_type
#   }
# }