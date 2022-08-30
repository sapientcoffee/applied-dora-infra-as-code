#!/usr/bin/env bash
set -eEuo pipefail

echo "--> Creating Cloud Build Trigger"
gcloud beta builds triggers create github \
  --name "iac-gcp" \
  --repo "my-infrastructure" \
  --branch-pattern "^main$" \
  --build-config "cloudbuild.yaml"
