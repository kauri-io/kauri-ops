#!/bin/sh

if [ "${TARGET_ENV}" == "" ]; then
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

##########################################
# 1. CLEANUP
echo
echo '# Cleanup'
kubectl delete all --all -n monitoring
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

kubectl apply -f ./elasticsearch-master.yml \
              -f ./elasticsearch-data.yml \
              -f ./elasticsearch-client.yml

waitForServiceNC "ElasticSearch cluster" elasticsearch-client localhost 9200

echo
echo 'Generating passwords'
sleep 10s
output=$(kubectl exec $(kubectl get pods -n monitoring | grep elasticsearch-client | sed -n 1p | awk '{print $1}')\
             -n monitoring \
             -- bin/elasticsearch-setup-passwords auto -b)

PW_ELASTIC=$(echo "$output" | grep '^PASSWORD elastic' | sed 's/PASSWORD elastic = \(.*\)/\1/')
echo elastic: $PW_ELASTIC

echo
echo 'Creating secrets:'
kubectl create secret generic elasticsearch-pw-elastic --from-literal password=$PW_ELASTIC -n monitoring


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
