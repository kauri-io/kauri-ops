#! /bin/bash

# Source library
source ../lib.sh

# Check whether script is running in a sub-shell
if [ "${BASH_SOURCE}" == "$0" ]; then
    log_error '"gemerateServices.sh" should be sourced. Use ". gemerateServices.sh --help" for detailed information.'
    exit 1
fi

# Check required tools. Exit if requirements aren't satisfied.
check_required_tools
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

print_banner 'Creating mongoDB service in Kubernetes...'
cd mongodb/scripts

./generateMongoDB.sh

cd ../..

print_banner 'Creating elasticsearch service in Kubernetes...'
cd elasticsearch
./generateES.sh

print_banner 'Creating kafka and zookeeper service in Kubernetes...'
cd ../helm/kafka
./generateKafka.sh

print_banner 'Creating IPFS service in Kubernetes...'
cd ../ipfs
./generateIPFS.sh

print_banner 'Creating Kibana service in Kubernetes...'
cd ../kibana
./generateKibana.sh

print_banner 'Creating geth service in Kubernetes...'
cd ../geth
./generateGeth.sh

print_banner 'Creating Logstash service in Kubernetes...'
cd ../../logstash
./generateLogstash.sh

cd ..

print_banner 'Service generation completed'
