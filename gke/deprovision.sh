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
#check_required_tools
#[[ $? -ne 0 ]] && exit 1

# Parse command line arguments
parse_args "$@"
[[ $? -ne 0 ]] && return 1

# Load config.json and export environment variables
load_config

# Delete kubenetes cluster
log_info "Start deleting kubenetes cluster ${ACS_NAME}..."
gcloud beta container clusters delete ${ACS_NAME}
