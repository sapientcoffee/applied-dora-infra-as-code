# Applied DORA - Infrastructure as Code using Google Cloud

Building upon the findings from the [DevOps Research and Assessment (DORA)](https://www.devops-research.com/research.html) program, this repo demonstrates an example approach for implementing an **Infrastructure as Code** strategy using Google Cloud.

This repo contains an example deployment approach using a combination of [Terraform](https://terraform.io) and [Kubernetes Resource Model (KRM)](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/architecture/resource-management.md). Terraform is used to deploy the base infrastructure (GKE, Config Connector) and KRM is used to deploy applications (Kubernetes Deployments/Services) and application depedencies (Cloud Firestore).

## Prerequisites

1. A Google Cloud project with billing set up. 
2. [gcloud](https://cloud.google.com/sdk/docs/quickstarts)
3. [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
4. [terraform](https://www.terraform.io/downloads.html)

## Terraform Base Infrastructure

The Terraform in the `infra` directory does the following: 
- Creates a 3-node zonal GKE cluster
- Configures Workload Identity
- Enables the Config Connector add-on
- Creates a service account and service account bindings for Config Connector
- Creates the required Config Connector resources, necessary to complete deployment

Change to the `infra` directory:

```
cd infra/
```

Update the `region`, `zone`, and `deployment_name` input variables in `terraform.tfvars`. Then, initialize the Terraform bits:

```
terraform init
```

When that's completed, you'll have the necessary providers and modules to deploy. 

Now use Terraform's `plan` mechanism to see what changes will be made:

```
terraform plan -var project_id=PROJECT_ID
```

Assuming that all looks good, go ahead and deploy:

```
terraform apply -auto-approve -var project_id=PROJECT_ID
```

Once the deployment is complete, we need to complete the Config Connector setup process. But first, setup `kubectl`:

```
gcloud container clusters get-credentials adora-iac-cluster --zone ZONE
```

Now apply the remaining resources to complete the setup:

```
kubectl apply -f configconnector.yaml
kubectl apply -f namespace.yaml
```

## KRM Application Infrastructure

TODO

## Resources

TODO

## Cleanup

```
terraform destroy
```

