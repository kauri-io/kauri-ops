#!/bin/bash
while [[ $# -gt 0 ]]; do
    case "$1" in
    -inputenv)
        if [[ $2 != 'uat' && $2 != 'dev' && $2 != 'dev2' ]]; then
            echo "Option argument to '-inputenv' can only be 'uat', 'dev', or 'dev2'."
            exit 1
        fi
        inputenv=$2
        shift
        ;;
    -targetenv)
        if [[ $2 != 'uat' && $2 != 'dev' && $2 != 'dev2' ]]; then
            echo "Option argument to '-targetenv' can only be 'uat', 'dev', or 'dev2'."
            exit 1
        fi
        if [[ $2 == $inputenv ]]; then
          echo "Argument -inputenv cannot be equal to -targetenv."
          exit 1
        fi
        targetenv=$2
        shift
        ;;
    *)
        echo "Invalid argument: $1"
        exit 1
    esac
    shift
done

if [[ "${inputenv}" == "" || "${targetenv}" == "" ]]; then
  echo "please set -inputenv and -targetenv"
  exit 1
fi

echo "Do something with $inputenv and $targetenv."

echo "##############################################################################################"
echo "Connecting to input env: $inputenv"
echo "##############################################################################################"
source env_setup.sh --config-file config/config-$inputenv.json
echo "##############################################################################################"
echo "Openning tunnel for mongodb in input env: $inputenv"
echo "##############################################################################################"
kubectl port-forward mongo-0 27017:27017 &
kubectl port-forward mongo-1 27018:27017 &
kubectl port-forward mongo-2 27019:27017 &
sleep 30
echo "##############################################################################################"
echo "Exporting mongo collections from env: $inputenv"
echo "##############################################################################################"
for COLLECTION in articleCheckpointSummary articleMeta collection comment community curatedList user vote
do
  mongoexport --uri "mongodb://127.0.0.1:27017,127.0.0.1:27018,127.0.0.1:27019/test?replicaSet=rs0" -c $COLLECTION --out $COLLECTION.file
done
killall -9 kubectl
echo "##############################################################################################"
echo "Setting up ingress for elasticsearch in input env: $inputenv"
echo "##############################################################################################"
kubectl apply -f importing/elastic-$inputenv-ingress.yml
echo "##############################################################################################"
echo "Connecting to target env: $targetenv"
echo "##############################################################################################"
source env_setup.sh --config-file config/config-$targetenv.json
echo "##############################################################################################"
echo "Openning tunnel for mongodb in target env: $targetenv"
echo "##############################################################################################"
kubectl port-forward mongo-0 27017:27017 &
kubectl port-forward mongo-1 27018:27017 &
kubectl port-forward mongo-2 27019:27017 &
sleep 30
echo "##############################################################################################"
echo "Running db cleanup in target env: $targetenv"
echo "##############################################################################################"
mongo < importing/cleandb.js
echo "##############################################################################################"
echo "Importing db data in target env: $targetenv"
echo "##############################################################################################"
for COLLECTION in articleCheckpointSummary articleMeta collection comment community curatedList user vote
do
  mongoimport --uri "mongodb://127.0.0.1:27017,127.0.0.1:27018,127.0.0.1:27019/test?replicaSet=rs0" -c $COLLECTION --file $COLLECTION.file
  rm $COLLECTION.file
done
killall -9 kubectl
echo "##############################################################################################"
echo "Openning tunnel for elasticsearch in target env: $targetenv"
echo "##############################################################################################"
kubectl port-forward $(kubectl get pod | grep elasticsearch-client | head -1 | awk '{print $1}') 9200:9200 &
sleep 30
echo "##############################################################################################"
echo "Cleaning elasticsearch indices in target env: $targetenv"
echo "##############################################################################################"
for INDEX in article community global checkpoint
do
  curl -X POST "localhost:9200/${INDEX}/_delete_by_query" -H 'Content-Type: application/json' -d'
  {
    "query": {
      "match_all": {}
    }
  }
  '
done
echo "##############################################################################################"
echo "Importing elasticsearch data in target env: $targetenv"
echo "##############################################################################################"
for INDEX in article community global checkpoint
do
  curl -X POST "localhost:9200/_reindex" -H 'Content-Type: application/json' -d'
  {
    "source": {
      "remote": {
        "host": "https://elastic.beta.kauri.io:443"
      },
      "index": "'${INDEX}'"
    },
    "dest": {
       "index": "'${INDEX}'"
    }
  }
  '
done
killall -9 kubectl
echo "##############################################################################################"
echo "Connecting to input env: $inputenv"
echo "##############################################################################################"
source env_setup.sh --config-file config/config-$inputenv.json
echo "##############################################################################################"
echo "Deleting ingress for elasticsearch in input env: $inputenv"
echo "##############################################################################################"
kubectl delete -f importing/elastic-$inputenv-ingress.yml
