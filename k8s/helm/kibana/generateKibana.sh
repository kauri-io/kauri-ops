#!/bin/sh
if [ "${TARGET_ENV}" == "" ]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi

helm install --name kibana-${TARGET_ENV} -f values-${TARGET_ENV}.yaml stable/kibana
