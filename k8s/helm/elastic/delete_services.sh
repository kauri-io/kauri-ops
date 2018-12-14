#!/bin/sh

if [ "${TARGET_ENV}" == "" ]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi

helm delete --purge elastic-${TARGET_ENV}
