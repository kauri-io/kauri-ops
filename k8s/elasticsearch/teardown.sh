#!/bin/sh
# Set the location to deploy to - run the following to see list of available locations: $ az account list-locations
LOCATN=${WEST_EUROPE}

k8_group=${TARGET_ENV}${K8_GROUP}${GROUP_SUFFIX}
storage_account=${TARGET_ENV}${ELASTIC_STORAGE_NAME}${GROUP_SUFFIX}

kubectl delete statefulsets es-data
kubectl delete services elasticsearch
kubectl delete services elasticsearch-discovery
kubectl delete services elasticsearch-data
kubectl delete deployments es-client
kubectl delete deployments es-master
sleep 3

# Delete persistent volume claims
kubectl delete persistentvolumeclaims -l role=data -l component=elasticsearch
sleep 3

#sed -e "s/LOCATN/${LOCATN}/g" azure-storageclass.yaml | sed -e "s/ELASTIC_STORAGE_NAME/${storage_account}/g" > /tmp/azure-storageclass.yaml
#kubectl delete -f /tmp/azure-storageclass.yaml
#rm /tmp/azure-storageclass.yaml
#sleep 5
