#!/bin/sh

# Set the location to deploy to - run the following to see list of available locations: $ az account list-locations
if [ "${TARGET_ENV}" == "" ]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi
kubectl apply --validate=false\
    -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm install --name cert-manager -f values.yaml jetstack/cert-manager
kubectl apply -f lets-encrypt-prod.yml
