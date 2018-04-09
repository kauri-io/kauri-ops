#!/bin/sh

# Set the location to deploy to - run the following to see list of available locations: $ az account list-locations
if [ "${TARGET_ENV}" == "" ]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi

helm install --name cert-manager -f values-${TARGET_ENV}.yaml stable/cert-manager
kubectl apply -f lets-encrypt-${TARGET_ENV}.yml
