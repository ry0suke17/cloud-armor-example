# cloud-armor-example

This is a repo to try out the Cloud Armor security policy.

## Setup

Create GKE cluster and security policy.

```shell
export TF_VAR_gcp_project=your-gcp-project
cd terraform/gcp
terraform-v1.5.7 apply

cd ../..
make k8s/apply GCP_PROJECT_ID=your-gcp-project
```

Install datadog agent if needed.

```shell
make k8s/create/secret DATADOG_API_KEY=your-api-key DATADOG_APP_KEY=your-app-key GCP_PROJECT_ID=your-gcp-project
make helm/install/datadog GCP_PROJECT_ID=your-gcp-project
```

## Try

Check the behavior of the security policy with the following command.

```shell
./scripts/too-many-request.sh http://${APP_IP_ADDRESS}/app1 20
```