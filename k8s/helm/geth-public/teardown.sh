#!/bin/sh

env=${TARGET_ENV}

if [ "${env}" == "" ]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi

helm delete --purge geth-${env}
