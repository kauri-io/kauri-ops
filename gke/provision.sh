#! /bin/bash
#
#
# Provision resources in Google Cloud

# Source library
source ../lib.sh

# Check whether script is running in a sub-shell
if [ "${BASH_SOURCE}" == "$0" ]; then
    log_error '"provision.sh" should be sourced. Use ". provision.sh --help" for detailed information.'
    exit 1
fi

# Check required tools. Exit if requirements aren't satisfied.
#check_required_tools_azure
#[[ $? -ne 0 ]] && return 1

# Parse command line arguments
parse_args "$@"
[[ $? -ne 0 ]] && return 1

# Load ${CONFIG_FILE} and export environment variables
load_config

# Check required environment variables
check_required_env_vars
[[ $? -ne 0 ]] && return 1

print_banner 'Start provisioning of kubenetes resources...'

create_kubernetes_gke ${ACS_NAME} ${K8_MASTER_COUNT} ${K8_MASTER_VM} ${K8_AGENT_COUNT} ${K8_AGENT_VM} ${K8S_VERSION}

gcloud container clusters get-credentials $ACS_NAME --zone $GOOGLE_ZONE

if [ -z "$(kubectl get ns ${TARGET_ENV} --ignore-not-found)" ]; then
  kubectl create ns ${TARGET_ENV} --save-config
fi
kubectl config set-context $(kubectl config current-context) --namespace=${TARGET_ENV}

kubectl create clusterrolebinding --user system:serviceaccount:kube-system:default kube-system-cluster-admin --clusterrole cluster-admin
kubectl create clusterrolebinding --user system:serviceaccount:${TARGET_ENV}:default ${TARGET_ENV}-cluster-edit --clusterrole edit

print_banner 'Initialising Helm & Tiller...'
helm init --upgrade


#Set up environment variables for local dev environment
cd ..
source env_setup.sh "$@"

print_banner 'Provision completed'
