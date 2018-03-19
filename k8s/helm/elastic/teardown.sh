#!/bin/sh

helm delete --purge elastic-dev
kubectl delete pvc -l release=elastic-dev,component=data
kubectl delete pvc -l release=elastic-dev,component=master
