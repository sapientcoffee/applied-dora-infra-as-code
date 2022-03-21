# This configures Terraform to store it state in the Google Cloud Storage bucket
# named coffee-with-rob-terraform-state. This is important so that the state can be
# accessed by multiple people or services (like Google Cloud Build).

# gcloud auth application-default login

terraform {
  backend "gcs" {
    bucket = "coffee-with-iac-state"
    prefix = "terraform/state/iac-gcp"
  }
}
