GCP_PROJECT_ID=your-gcp-project-id

K8S_VERSION=1.27.3

GKE_CLUSTER_NAME=test-cluster
GKE_REGION=us-west1
GKE_ZONE=${GKE_REGION}-a

DATADOG_HELM_CHART_VERSION=3.38.1
DATADOG_API_KEY=your-datadog-api-key
DATADOG_APP_KEY=your-datadog-app-key

gcp/project/check:
	 if [ `gcloud config list 2> /dev/null | grep "project = ${GCP_PROJECT_ID}" | wc -l` -eq 0 ]; then >&2 echo "ERROR: project is not ${GCP_PROJECT_ID}"; exit 1; fi

gke/context/use:
	gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --region ${GKE_REGION}
	kubectl config use-context gke_${GCP_PROJECT_ID}_${GKE_REGION}_${GKE_CLUSTER_NAME}

k8s/validate:
	# ref. https://github.com/yannh/kubernetes-json-schema/
	kustomize build ./k8s/test/hello-app1 | kubeconform -kubernetes-version ${K8S_VERSION} -strict -skip BackendConfig
	kustomize build ./k8s/test/hello-app2 | kubeconform -kubernetes-version ${K8S_VERSION} -strict -skip BackendConfig

k8s/create/secret: gcp/project/check gke/context/use
	# ref. https://docs.datadoghq.com/ja/containers/kubernetes/installation/?tab=helm#%E3%83%81%E3%83%A3%E3%83%BC%E3%83%88%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB
	kubectl create secret generic datadog-secret --from-literal api-key=${DATADOG_API_KEY} --from-literal app-key=${DATADOG_APP_KEY}

# need to create secret before executing
k8s/apply: gcp/project/check gke/context/use
	kustomize build ./k8s/test/hello-app1 | kubectl apply -f -
	kustomize build ./k8s/test/hello-app2 | kubectl apply -f -

helm/install/datadog: gcp/project/check gke/context/use
	helm-v3.8.1 install datadog-agent \
		-f ./k8s/helm/datadog/datadog-values.yaml \
		--set targetSystem=linux \
		--version ${DATADOG_HELM_CHART_VERSION} \
		datadog/datadog
