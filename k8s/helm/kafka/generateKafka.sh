#!/bin/sh

if [ "${TARGET_ENV}" == "" ] || [ "${DEFAULT_STORAGE_NAME}" == "" ]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi

# Register Azure persistent disks to be used by dyanmically created persistent volumes
sed -e "s/storageclass/${DEFAULT_STORAGE_NAME}/g" values-${TARGET_ENV}.yaml > /tmp/values.yaml
helm install --name kafka-${TARGET_ENV} -f /tmp/values.yaml ./kafka
rm /tmp/values.yaml
