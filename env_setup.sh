#! /bin/bash
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
#
#
# Setup environment variables for development

# Source library
source lib.sh

# Check whether script is running in a sub-shell
if [ "${BASH_SOURCE}" == "$0" ]; then
    log_error '"env_setup.sh" should be sourced. Run "source env_setup.sh" or ". env_setup.sh"'
    exit 1
fi

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
