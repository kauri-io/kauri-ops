#!/bin/sh

if [ "${TARGET_ENV}" == "" ] || [ "${DEFAULT_STORAGE_NAME}" == "" ]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi

sed -e "s/storageclass/${DEFAULT_STORAGE_NAME}/g" values-${TARGET_ENV}.yaml > /tmp/values.yaml
helm install --name kafka-${TARGET_ENV} -f /tmp/values.yaml incubator/kafka
rm /tmp/values.yaml
