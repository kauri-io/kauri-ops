#!/bin/sh

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
