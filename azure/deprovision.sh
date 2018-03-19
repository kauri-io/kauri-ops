#! /bin/bash
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
#
#
# Utility script to de-provision Azure resources

# Source library
source ../lib.sh

# Check required tools. Exit if requirements aren't satisfied.
check_required_tools
[[ $? -ne 0 ]] && exit 1

# Parse command line arguments
parse_args "$@"
[[ $? -ne 0 ]] && return 1

# Load config.json and export environment variables
load_config

export TEARDOWN_NO_WAIT=true

# Prefix resource group names with target environment
c_group=${TARGET_ENV}${COMMON_GROUP}${GROUP_SUFFIX}
k8_group=${TARGET_ENV}${K8_GROUP}${GROUP_SUFFIX}

# Delete resource groups in parallel
log_info "Start deleting resource group ${c_group}..."
az group delete -y -n ${c_group} --no-wait
log_info "Start deleting resource group ${k8_group}..."
az group delete -y -n ${k8_group} --no-wait


# Wait for completion if called with '--wait'
if [ "${TEARDOWN_NO_WAIT}" != "true" ]; then
  log_info "\nWait for delete completion..."

  az group wait -n ${c_group} --deleted

  az group wait -n ${k8_group} --deleted

  log_info "\nAll deleted."
fi
