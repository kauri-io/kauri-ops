

c_group=${TARGET_ENV}${COMMON_GROUP}${GROUP_SUFFIX}
k8_group=${TARGET_ENV}${K8_GROUP}${GROUP_SUFFIX}

output=$(truffle migrate --network k8sdev --reset)
CHECKPOINT_CONTRACT_ADDRESS=$(echo "$output" | grep '^KauriCheckpoint address:' | sed 's/KauriCheckpoint address: //')
echo KauriCheckpoint Contract Address: $CHECKPOINT_CONTRACT_ADDRESS

if [ -n "$(kubectl get secret smart-contract-addresses --ignore-not-found)" ]; then
  kubectl delete secret smart-contract-addresses
fi

kubectl create secret generic smart-contract-addresses \
                                                --namespace=${TARGET_ENV} \
                                                --from-literal=KauriCheckpointContractAddress=$CHECKPOINT_CONTRACT_ADDRESS