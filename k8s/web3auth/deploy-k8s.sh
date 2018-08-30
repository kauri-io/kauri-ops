if [ "${TARGET_ENV}" == "" ]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi
# Create app if not exists
kubectl apply -f web3auth-service.yml || true
kubectl apply -f web3auth-config.yml || true
kubectl apply -f web3auth-deployment-${TARGET_ENV}.yml || true
