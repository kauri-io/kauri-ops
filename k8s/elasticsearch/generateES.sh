#!/bin/sh

# Set the location to deploy to - run the following to see list of available locations: $ az account list-locations
if [ "${TARGET_ENV}" == "" ] || [ "${DEFAULT_STORAGE_NAME}" == "" ]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi

kubectl apply -f es-discovery-svc.yaml
kubectl apply -f es-svc.yaml
kubectl apply -f es-master-${TARGET_ENV}.yaml

sleep 30

kubectl apply -f es-client-${TARGET_ENV}.yaml
kubectl apply -f es-data-svc.yaml
sed -e "s/storageclass/${DEFAULT_STORAGE_NAME}/g" es-data-stateful-${TARGET_ENV}.yaml > /tmp/k8s-service.yaml
kubectl apply -f /tmp/k8s-service.yaml
rm /tmp/k8s-service.yaml
