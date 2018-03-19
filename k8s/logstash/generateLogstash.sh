#!/bin/sh
env=${TARGET_ENV}
kubectl create -f filebeat-ds.yaml
kubectl create -f logstash-config-${env}.yaml
kubectl create -f logstash-service.yaml
kubectl create -f logstash-deployment.yaml
