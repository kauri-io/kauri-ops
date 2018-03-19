#!/bin/sh

# Delete mongod stateful set + mongodb service + secrets + host vm configuer daemonset
kubectl delete statefulsets mongo
kubectl delete services mongo
sleep 3

# Delete persistent volume claims
kubectl delete persistentvolumeclaims -l role=mongo
