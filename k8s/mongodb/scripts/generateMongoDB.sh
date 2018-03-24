#!/bin/sh
##
# Script to deploy a Kubernetes project with a StatefulSet running a MongoDB Replica Set, to Azure ACS.
##

if [ "${TARGET_ENV}" == "" ] || [ "${DEFAULT_STORAGE_NAME}" == "" ]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi


#
sed -e "s/storageclass/${DEFAULT_STORAGE_NAME}/g" ../mongodb-service-${TARGET_ENV}.yaml > /tmp/k8s-service.yaml
kubectl apply -f /tmp/k8s-service.yaml
rm /tmp/k8s-service.yaml
sleep 5

# Print current deployment state (unlikely to be finished yet)
kubectl get all
kubectl get persistentvolumes
echo
echo "Keep running the following command until all 'mongod-n' pods are shown as running:  kubectl get all"
echo
