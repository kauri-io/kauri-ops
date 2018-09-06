if [ "${TARGET_ENV}" == "" ]; then
  echo "Environment not set, please run env_setup script in ops folder"
  exit 1
fi

# Delete app if not exists
kubectl delete -f web3auth-service.yml || true
kubectl delete -f web3auth-config.yml || true
kubectl delete -f web3auth-deployment-${TARGET_ENV}.yml || true
