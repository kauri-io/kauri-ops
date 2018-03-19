#! /bin/bash
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
#
#
# Utility script to de-provision Azure resources

# Source library
source ../lib.sh

# Check whether script is running in a sub-shell
if [ -z "${TARGET_ENV}" ]; then
    log_error 'Environment not setup, please source env_setup.sh first'
    exit 1
fi

c_group=${TARGET_ENV}${COMMON_GROUP}${GROUP_SUFFIX}
k8_group=${TARGET_ENV}${K8_GROUP}${GROUP_SUFFIX}

az acr login -n ${c_group}acr
