#!/bin/sh

# Set the location to deploy to - run the following to see list of available locations: $ az account list-locations

if [ "${TARGET_ENV}" == "" ] || [ "${DEFAULT_STORAGE_NAME}" == "" ]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi

if [ "${TARGET_ENV}" == "uat" ]; then
  network="rinkeby"
elif [ "${TARGET_ENV}" == "prod" ]; then
  network="mainnet"
else
  echo "Unknown environment ${TARGET_ENV}"
  exit 1
fi

sed -e "s/storageclass/${DEFAULT_STORAGE_NAME}/g" ${network}/values.yaml > /tmp/values.yaml
helm install --name geth-${TARGET_ENV} -f /tmp/values.yaml ./geth
rm /tmp/values.yaml
