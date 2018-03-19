#! /bin/bash
#
#
# Provision resources in Azure

# Source library
source ../lib.sh

# Check whether script is running in a sub-shell
if [ "${BASH_SOURCE}" == "$0" ]; then
    log_error '"provision.sh" should be sourced. Use ". provision.sh --help" for detailed information.'
    exit 1
fi

# Check required tools. Exit if requirements aren't satisfied.
check_required_tools_azure
[[ $? -ne 0 ]] && return 1

# Parse command line arguments
parse_args "$@"
[[ $? -ne 0 ]] && return 1

# Load ${CONFIG_FILE} and export environment variables
load_config

# Check required environment variables
check_required_env_vars
[[ $? -ne 0 ]] && return 1

c_group=${TARGET_ENV}${COMMON_GROUP}${GROUP_SUFFIX}
k8_group=${TARGET_ENV}${K8_GROUP}${GROUP_SUFFIX}

print_banner 'Start provisioning container registry...'
az group create -n ${c_group} -l ${WEST_EUROPE}
create_container_registry ${c_group}

print_banner 'Start provisioning of kubenetes resources...'

az group create -n ${k8_group} -l ${WEST_EUROPE}
create_kubernetes_aks ${k8_group} ${ACS_NAME} ${K8_MASTER_COUNT} ${K8_MASTER_VM} ${K8_AGENT_COUNT} ${K8_AGENT_VM} ${K8S_VERSION}

sleep 60
#TODO fix issue where connection timesouts creating secrets on first run

print_banner 'Creating secrets and config map in Kubernetes...'
create_secrets_in_kubernetes_aks ${k8_group} ${ACS_NAME} ${c_group}


print_banner 'Initialising Helm & Tiller...'
helm init --upgrade


#Set up environment variables for local dev environment
source ../env_setup.sh "$@"

#print_banner 'Creating service principle for travisCI...'
#pwd=$(date +%s | sha256sum | base64 | head -c 32)
#az ad sp create-for-rbac --name travis-${TARGET_ENV} --password ${pwd}

print_banner 'Provision completed'
