#! /bin/bash
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
#
#
# Bash function library

##############################################################################
# Show help message
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function show_help()
{
  echo "
Usage:
    source [shell script] [options]
    . [shell script] [options]

Options:
    --config-file [value]    Configuration file to use.
"
}

##############################################################################
# Show help message
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function show_teardown_help()
{
  echo "
Deprovision.sh will delete all Azure resources created by provision.sh.

Usage:
    bash teardown.sh [options]
    ./teardown.sh [options]

Options:
    --env [value]           Optional. Target environment to provision.
                            Allow values: dev, test, prod. Default is 'dev'.
    --group-suffix [value]  Optional. Suffix of provisioned resource groups. Default is empty.
    --wait                  Optional. If this options is specified, script will wait until all resource groups are deleted successfully.
                            By default, script will initiate the deletion of resource groups and exit immediately.
"
}

##############################################################################
# Check whether tool is installed
# Globals:
#   None
# Arguments:
#   tool_name
#   test_command
# Returns:
#   None
##############################################################################
function check_tool()
{
  local tool_name=$1
  local test_command=$2
  ${test_command} > /dev/null 2>&1
  if [ $? != 0 ]; then
    log_error "\"${tool_name}\" not found. Please install \"${tool_name}\" before running this script."
    return 1
  fi
}

##############################################################################
# Check whether all required tools are installed
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function check_required_tools_azure()
{
  check_tool 'Java SDK' 'javac -version'
  [[ $? -ne 0 ]] && return 1

  check_tool 'Maven' 'mvn --version'
  [[ $? -ne 0 ]] && return 1

  check_tool 'Azure CLI 2.0' 'az --version'
  [[ $? -ne 0 ]] && return 1

  check_tool 'docker' 'docker --version'
  [[ $? -ne 0 ]] && return 1

  check_tool 'jq' 'jq -h'
  [[ $? -ne 0 ]] && return 1

  check_tool 'gettext' 'envsubst -h'
  [[ $? -ne 0 ]] && return 1

  check_tool 'kubectl' 'kubectl'
  [[ $? -ne 0 ]] && return 1

  return 0
}



##############################################################################
# Check whether all required environment variables are set up
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function check_required_env_vars()
{
    return 0
}

##############################################################################
# Parse arguments and setup environment variables
# Globals:
#   CONFIG_FILE
# Arguments:
#   All args from command line
# Returns:
#   None
##############################################################################
function parse_args()
{
  if [ -z "$1" ]; then
    show_help
    return 1
  fi

  while :; do
    case "$(echo $1 | tr '[:upper:]' '[:lower:]')" in
      -h|-\?|--help)
        show_help
        return 1
        ;;
      --config-file)
        if [ -n "$2" ]; then
          export CONFIG_FILE=$2
          shift
        else
          log_error "\"--config-file\" requires an argument."
          return 1
        fi
        ;;
      -?*)
        log_warning "Unknown option \"$1\""
        ;;
      *)
        break
    esac

    shift
  done
}

##############################################################################
# Read all key-value pairs from config.json and export as environment variables
# Globals:
#   Environment variables set in config.json
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function load_config()
{
  local keys=( $(jq -r '.[] | values[] | select(.value != "").key' ${CONFIG_FILE}) )
  local values=( $(jq -r '.[] | values[] | select(.value != "").value' ${CONFIG_FILE}) )

  local total=${#keys[*]}
  for ((i=0; i < $((total)); i++))
  do
    #On Windows, there seems to be special line ending characters. Remove them.
    local key=${keys[$i]}
    key=${key//$'\n'/}
    key=${key//$'\r'/}
    local value=${values[$i]}
    value=${value//$'\n'/}
    value=${value//$'\r'/}
    export ${key}=${value}
  done
}

##############################################################################
# Create shared resources with master ARM template
# Globals:
#   None
# Arguments:
#   resource_group
# Returns:
#   None
##############################################################################
function create_container_registry()
{
  local resource_group=$1
  az acr create --resource-group=${resource_group} --name=${resource_group}ACR --sku=Basic --admin-enabled=true
}

##############################################################################
# Wait for the completion of ARM template deployment
# Globals:
#   None
# Arguments:
#   resource_group
#   deployment_name
# Returns:
#   None
##############################################################################
function wait_till_deployment_created()
{
   local resource_group=$1
   local deployment_name=$2
   az group deployment wait -g ${resource_group} -n ${deployment_name} --created
   if [ $? != 0 ]; then
    log_error "Something is wrong when provisioning resources in resource group \"${resource_group}\". Please check out logs in Azure Portal."
    return 1
   fi
}

##############################################################################
# Create linux container web app
# Globals:
#   None
# Arguments:
#   resource_group
#   location
# Returns:
#   None
##############################################################################
function create_webapp()
{
  local resource_group=$1
  local location=$2
  az group deployment create -g ${resource_group} --template-file ./arm/linux-webapp.json \
                            --parameters "{\"location\": {\"value\": \"${location}\"}}" \
                            --query "{id:id,name:name,provisioningState:properties.provisioningState,resourceGroup:resourceGroup}"
}

##############################################################################
# Create Kubernetes cluster without waiting if it doesn't exist
# Globals:
#   None
# Arguments:
#   resource_group
#   acs_name
# Returns:
#   None
##############################################################################
function create_kubernetes_acs()
{
  local resource_group=$1
  local acs_name=$2
  local master_count=$3
  local master_size=$4
  local agent_count=$5
  local agent_size=$6

  if [ -z "$(az acs show -g ${resource_group} -n ${acs_name})" ]; then
    az acs create --orchestrator-type=kubernetes -g ${resource_group} -n ${acs_name} \
                  --generate-ssh-keys --agent-count ${agent_count} --agent-vm-size ${agent_size} \
                  --master-count ${master_count} --master-vm-size=${master_size}
  fi
}

##############################################################################
# Create Kubernetes cluster without waiting if it doesn't exist
# Globals:
#   None
# Arguments:
#   resource_group
#   acs_name
# Returns:
#   None
##############################################################################
function create_kubernetes_gke()
{
  local acs_name=$1
  local master_count=$2
  local master_size=$3
  local agent_count=$4
  local agent_size=$5
  local k8s_version=$6

  if [ -z "$(gcloud beta container clusters describe ${acs_name})" ]; then
    gcloud beta container clusters create ${acs_name} \
                  --num-nodes ${agent_count} --machine-type ${agent_size}

    kubectl create clusterrolebinding --user system:serviceaccount:kube-system:default kube-system-cluster-admin --clusterrole cluster-admin
    kubectl create clusterrolebinding --user system:serviceaccount:default:default default-cluster-edit --clusterrole edit
  fi
}


##############################################################################
# Create Kubernetes cluster without waiting if it doesn't exist
# Globals:
#   None
# Arguments:
#   resource_group
#   acs_name
# Returns:
#   None
##############################################################################
function create_kubernetes_aks()
{
  local resource_group=$1
  local acs_name=$2
  local master_count=$3
  local master_size=$4
  local agent_count=$5
  local agent_size=$6
  local k8s_version=$7

  if [ -z "$(az aks show -g ${resource_group} -n ${acs_name})" ]; then
    az aks create -g ${resource_group} -n ${acs_name} --kubernetes-version ${k8s_version} \
                  --generate-ssh-keys --node-count ${agent_count} --node-vm-size ${agent_size}
  fi
}

##############################################################################
# Wait for the completion of Kubernetes cluster creation
# Globals:
#   None
# Arguments:
#   resource_group
#   acs_name
# Returns:
#   None
##############################################################################
function wait_till_kubernetes_created() {
  local resource_group=$1
  local acs_name=$2
  az acs wait -g ${resource_group} -n ${acs_name} --created
  if [ $? != 0 ]; then
    log_error "Something is wrong when provisioning Kubernetes in resource group \"${resource_group}\". Please check out logs in Azure Portal."
    return 1
  fi
}

##############################################################################
# Create ConfigMap and Secrets in Kubernetes cluster
# Globals:
#   TARGET_ENV
#   MYSQL_ENDPOINT
#   MYSQL_USERNAME
#   MYSQL_PASSWORD
# Arguments:
#   resource_group
#   acs_name
# Returns:
#   None
##############################################################################
function create_secrets_in_kubernetes_acs() {
  local resource_group=$1
  local acs_name=$2
  local common_resource_group=$3

  az acs kubernetes get-credentials -g ${resource_group} -n ${acs_name}

  if [ -z "$(kubectl get ns ${TARGET_ENV} --ignore-not-found)" ]; then
    kubectl create ns ${TARGET_ENV} --save-config
  fi
  kubectl config set-context $(kubectl config current-context) --namespace=${TARGET_ENV}

  if [ -n "$(kubectl get secret regsecret --ignore-not-found)" ]; then
    kubectl delete secret regsecret
  fi

  CR_PASSWORD=$(az acr credential show --name=${common_resource_group}ACR --query passwords[0].value | sed "s/\"//g")
  kubectl create secret docker-registry regsecret \
                                           --namespace=${TARGET_ENV} \
                                           --docker-server=${common_resource_group}acr.azurecr.io \
                                           --docker-username=${common_resource_group}acr \
                                           --docker-email 'example@example.com' \
                                           --docker-password=$CR_PASSWORD
}


##############################################################################
# Create ConfigMap and Secrets in Kubernetes cluster
# Globals:
#   TARGET_ENV
#   MYSQL_ENDPOINT
#   MYSQL_USERNAME
#   MYSQL_PASSWORD
# Arguments:
#   resource_group
#   acs_name
# Returns:
#   None
##############################################################################
function create_secrets_in_kubernetes_aks() {
  local resource_group=$1
  local acs_name=$2
  local common_resource_group=$3

  az aks get-credentials -g ${resource_group} -n ${acs_name}

  if [ -z "$(kubectl get ns ${TARGET_ENV} --ignore-not-found)" ]; then
    kubectl create ns ${TARGET_ENV} --save-config
  fi
  kubectl config set-context $(kubectl config current-context) --namespace=${TARGET_ENV}

  if [ -n "$(kubectl get secret regsecret --ignore-not-found)" ]; then
    kubectl delete secret regsecret
  fi

  CR_PASSWORD=$(az acr credential show --name=${common_resource_group}ACR --query passwords[0].value | sed "s/\"//g")
  kubectl create secret docker-registry regsecret \
                                           --namespace=${TARGET_ENV} \
                                           --docker-server=${common_resource_group}acr.azurecr.io \
                                           --docker-username=${common_resource_group}acr \
                                           --docker-email 'example@example.com' \
                                           --docker-password=$CR_PASSWORD
}

##############################################################################
# Deploy Jenkins if it doesn't exist
# Globals:
#   GITHUB_REPO_OWNER
#   GITHUB_REPO_NAME
#   JENKINS_PASSWORD
#   GROUP_SUFFIX
# Arguments:
#   resource_group
#   acs_name
# Returns:
#   None
##############################################################################
function deploy_jenkins()
{
  create_secrets_in_jenkins_kubernetes $1 $2

  if [ -z "$(kubectl get deploy jenkins --ignore-not-found --namespace=jenkins)" ]; then
    kubectl apply -f ./jenkins/jenkins-master.yaml
  fi

  # Check existence of Jenkins service
  check_jenkins_readiness
}

##############################################################################
# Create secrets in Kubernetes for Jenkins
# Globals:
#   None
# Arguments:
#   resource_group
#   acs_name
# Returns:
#   None
##############################################################################
function create_secrets_in_jenkins_kubernetes() {
  local resource_group=$1
  local acs_name=$2

  az acs kubernetes get-credentials -g ${resource_group} -n ${acs_name}

  if [ -z "$(kubectl get ns jenkins --ignore-not-found)" ]; then
    kubectl create ns jenkins --save-config
  fi
  kubectl config set-context $(kubectl config current-context) --namespace=jenkins

  if [ -n "$(kubectl get secret my-secrets --ignore-not-found)" ]; then
    kubectl delete secret my-secrets
  fi
  kubectl create secret generic my-secrets --from-literal=jenkinsPassword=${JENKINS_PASSWORD} --save-config

  if [ -n "$(kubectl get secret kube-config --ignore-not-found)" ]; then
    kubectl delete secret kube-config
  fi
  kubectl create secret generic kube-config --from-file=config=${HOME}/.kube/config

  if [ -n "$(kubectl get configMap my-config --ignore-not-found)" ]; then
    kubectl delete configmap my-config
  fi
  kubectl create configmap my-config --save-config \
                                    --from-literal=githubRepoOwner=${GITHUB_REPO_OWNER} \
                                    --from-literal=githubRepoName=${GITHUB_REPO_NAME} \
                                    --from-literal=groupSuffix=${GROUP_SUFFIX}
}

##############################################################################
# Check whether Jenkins is ready for access
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function check_jenkins_readiness()
{
  while [ 1 ]
  do
    jenkins_ip=$(kubectl get svc -o jsonpath={.items[*].status.loadBalancer.ingress[0].ip})
    if [ -n "${jenkins_ip}" ]; then
      break;
    fi
    sleep 5
  done
  echo Jenkins is ready at http://${jenkins_ip}/.
}

##############################################################################
# Export Jenkins URL as environment variables
# Globals:
#   JENKINS_URL
# Arguments:
#   resource_group
#   acs_name
# Returns:
#   None
##############################################################################
function export_jenkins_url()
{
  local resource_group=$1
  local acs_name=$2
  az acs kubernetes get-credentials -g ${resource_group} -n ${acs_name}
  export JENKINS_URL=$(kubectl get svc -o jsonpath={.items[*].status.loadBalancer.ingress[0].ip} --namespace=jenkins)
}

##############################################################################
# Export Azure Container Registry information as environment variables
# Globals:
#   ACR_NAME
#   ACR_USERNAME
#   ACR_PASSWORD
#   ACR_LOGIN_SERVER
# Arguments:
#   resource_group
# Returns:
#   None
##############################################################################
function export_acr_details()
{
  local resource_group=$1
  export ACR_NAME=$(az acr list -g ${resource_group} --query [0].name | tr -d '"')
  if [ -z "${ACR_NAME}" ]; then
    echo No Azure Container Registry found. Exit...
    exit 1
  fi
  export ACR_USERNAME=$(az acr credential show -g ${resource_group} -n ${ACR_NAME} --query username | tr -d '"')
  export ACR_PASSWORD=$(az acr credential show -g ${resource_group} -n ${ACR_NAME} --query passwords[0].value | tr -d '"')
  export ACR_LOGIN_SERVER=$(az acr show -g ${resource_group} -n ${ACR_NAME} --query loginServer | tr -d '"')
}

##############################################################################
# Export MySQL server information as environment variables
# Globals:
#   MYSQL_USERNAME
#   MYSQL_SERVER_ENDPOINT
#   MYSQL_ENDPOINT
# Arguments:
#   resource_group
# Returns:
#   None
##############################################################################
function export_database_details()
{
  local resource_group=$1
  local server_name=$(az mysql server list -g ${resource_group} --query [0].name | tr -d '"')
  local username=$(az mysql server show -g ${resource_group} -n ${server_name} --query administratorLogin | tr -d '"')
  local endpoint=$(az mysql server show -g ${resource_group} -n ${server_name} --query fullyQualifiedDomainName | tr -d '"')
  local database_name=$(az mysql db list -g ${resource_group} --server-name ${server_name} --query [0].name | tr -d '"')

  export MYSQL_USERNAME=${username}@${server_name}
  export MYSQL_SERVER_ENDPOINT=jdbc:mysql://${endpoint}:3306/?serverTimezone=UTC
  export MYSQL_ENDPOINT=jdbc:mysql://${endpoint}:3306/${database_name}?serverTimezone=UTC
}

##############################################################################
# Populate initial data set to MySQL database
# Globals:
#   None
# Arguments:
#   resource_group
# Returns:
#   None
##############################################################################
function init_database()
{
  local resource_group=$1
  export_database_details ${resource_group}
  cd ../database; mvn sql:execute; cd ../deployment
}

##############################################################################
# Export Redis server information as environment variables
# Globals:
#   REDIS_HOST
#   REDIS_PASSWORD
# Arguments:
#   resource_group
# Returns:
#   None
##############################################################################
function export_redis_details()
{
  local resource_group=$1
  local redis_name=$(az redis list -g ${resource_group} --query [0].name | tr -d '"')

  export REDIS_HOST=$(az redis show -g ${resource_group} -n ${redis_name} --query hostName | tr -d '"')
  export REDIS_PASSWORD=$(az redis list-keys -g ${resource_group} -n ${redis_name} --query primaryKey | tr -d '"')
}

##############################################################################
# Export image storage account information as environment variables
# Globals:
#   STORAGE_CONNECTION_STRING
# Arguments:
#   resource_group
# Returns:
#   None
##############################################################################
function export_image_storage()
{
  local resource_group=$1
  storage_name=$(az storage account list -g ${resource_group} --query [2].name | tr -d '"')
  export STORAGE_CONNECTION_STRING=$(az storage account show-connection-string -g ${resource_group} -n ${storage_name} --query connectionString | tr -d '"')
}

##############################################################################
# Export web-app information as environment variables
# Globals:
#   WEBAPP_NAME
#   WEBAPP_PLAN
# Arguments:
#   resource_group
# Returns:
#   None
##############################################################################
function export_webapp_details()
{
  local resource_group=$1
  local prefix=$2
  export ${prefix}_WEBAPP_NAME=$(az resource list -g ${resource_group} --resource-type Microsoft.Web/sites --query [0].name | tr -d '"')
  export ${prefix}_WEBAPP_PLAN=$(az appservice plan list -g ${resource_group} --query [0].name | tr -d '"')
}

##############################################################################
# Export data-app IP as environment variables
# Globals:
#   DATA_API_URL
# Arguments:
#   namespace
#   resource_group
# Returns:
#   None
##############################################################################
function export_data_api_url()
{
  local namespace=$1
  local resource_group=$2
  local k8_context=$(az acs list -g ${resource_group} --query [0].masterProfile.dnsPrefix | tr '[:upper:]' '[:lower:]' | tr -d '"')
  kubectl config use-context ${k8_context} > /dev/null
  export DATA_API_URL=$(kubectl get services -o jsonpath={.items[*].status.loadBalancer.ingress[0].ip} --namespace=${namespace})
}

##############################################################################
# Print string in specified color
# Globals:
#   None
# Arguments:
#   color
#   info
# Returns:
#   None
##############################################################################
function log_with_color()
{
  local color=$1
  local no_color='\033[0m'
  local info=$2
  echo -e "${color}${info}${no_color}"
}

##############################################################################
# Print information string in green color
# Globals:
#   None
# Arguments:
#   info
# Returns:
#   None
##############################################################################
function log_info()
{
  local info=$1
  local green_color='\033[0;32m'
  log_with_color "${green_color}" "${info}"
}

##############################################################################
# Print warning string in yellow color
# Globals:
#   None
# Arguments:
#   info
# Returns:
#   None
##############################################################################
function log_warning()
{
  local info=$1
  local yellow_color='\033[0;33m'
  log_with_color "${yellow_color}" "[Warning] ${info}"
}

##############################################################################
# Print error string in green color
# Globals:
#   None
# Arguments:
#   info
# Returns:
#   None
##############################################################################
function log_error()
{
  local info=$1
  local red_color='\033[0;31m'
  log_with_color "${red_color}" "[Error] ${info}"
}

##############################################################################
# Print activity banner
# Globals:
#   None
# Arguments:
#   info
# Returns:
#   None
##############################################################################
function print_banner()
{
  local info=$1
  log_info '********************************************************************************'
  log_info "* ${info}"
  log_info '********************************************************************************'
}
