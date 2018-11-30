#!/bin/sh
##

LOCATN=${WEST_EUROPE}
env=${TARGET_ENV}


helm delete --purge kafka-${env}

# Delete persistent volume claims
kubectl delete persistentvolumeclaims -l app=kafka
kubectl delete persistentvolumeclaims -l app=zookeeper
