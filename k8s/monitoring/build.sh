#!/bin/bash

echo "###################### BUILD MONITORING (env=${TARGET_ENV})" 

if [[ -z "${TARGET_ENV}" ]]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi

##########################################
# COMMON
waitForServiceCurl ()
{
  echo
  echo Waiting until $1 ready
  sleep 5s
  until $(kubectl exec -n monitoring $(kubectl get pods -n monitoring | grep $2 | sed -n 1p | awk '{print $1}') -- curl --connect-timeout 5 --max-time 5 --output /dev/null --silent --head --fail $3 2>/dev/null); do
    printf '.'
    sleep 3s
  done
  echo
  echo $1 ready!
}
waitForServiceNC ()
{
  echo
  echo Waiting until $1 ready
  sleep 5s
  while ! $(kubectl exec -n monitoring $(kubectl get pods -n monitoring | grep $2 | sed -n 1p | awk '{print $1}') -- nc -z $3 $4 2>/dev/null); do
    printf '.'
    sleep 3s
  done
  echo
  echo $1 ready!
}
createSecret ()
{
  kubectl delete secrets -n monitoring $1
  kubectl create secret generic $1 --from-literal password=$2 -n monitoring
}
##########################################
# 0. CLEANUP
echo
echo '# Cleanup'
kubectl delete all --all -n monitoring
kubectl delete ingress -n dev monitoring-kibana-ingress monitoring-apm-ingress
kubectl delete pvc -n monitoring elasticsearch-data-persistent-storage-elasticsearch-data-0
kubectl delete secrets -n monitoring --all
kubectl delete service -n dev kibana-ext


##########################################
# 1. NAMESPACE
echo
echo '# Create namespace "monitoring"'
kubectl apply -f ./monitoring.namespace.yml



##########################################
# 2. ELASTICSEARCH
echo
echo '# Install ElasticSearch cluster'

# kubectl apply -f ./elasticsearch-master.yml \
#               -f ./elasticsearch-data.yml \
#               -f ./elasticsearch-client.yml
createSecret elasticsearch-pw-elastic ""
kubectl apply -f ./elasticsearch.yml

waitForServiceNC "ElasticSearch cluster" elasticsearch localhost 9200

echo
echo 'Generating passwords'
sleep 10s
output=$(kubectl exec $(kubectl get pods -n monitoring | grep elasticsearch | sed -n 1p | awk '{print $1}')\
             -n monitoring \
             -- bin/elasticsearch-setup-passwords auto -b)

PW_ELASTIC=$(echo "$output" | grep '^PASSWORD elastic' | sed 's/PASSWORD elastic = \(.*\)/\1/')
echo elastic: $PW_ELASTIC

echo
echo 'Creating secrets:'
createSecret elasticsearch-pw-elastic $PW_ELASTIC

echo
echo 'Hot Configuration:'
kubectl exec -n monitoring elasticsearch-0 -- curl -XPUT 'http://localhost:9200/_template/default' -uelastic:$PW_ELASTIC -H 'Content-Type: application/json' -d '{
  "index_patterns": ["*"],
  "order": -1,
  "settings": {
    "number_of_shards": "1",
    "number_of_replicas": "0"
  }
}'

##########################################
# 3. KIBANA
echo
echo '# Install Kibana'

kubectl apply -f ./kibana.yml

waitForServiceCurl Kibana kibana "http://localhost:5601/monitoring/ui"


##########################################
# 4. APM SERVER
echo
echo '# Install APM Server'

kubectl apply -f ./apm-server.yml

waitForServiceCurl "APM Server" apm-server "http://localhost:8200"


##########################################
# 5. FILEBEAT
echo
echo '# Install Filebeat'

kubectl apply -f ./filebeat.yml


##########################################
# 6. METRICBEAT
echo
echo '# Install Metricbeat'

kubectl apply -f ./kube-state-metrics.yml
kubectl apply -f ./metricbeat.yml


##########################################
# 7. METRICBEAT
echo
echo '# Extra configuration'

kubectl apply -f ./monitoring.env.${TARGET_ENV}.yml
