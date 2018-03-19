

c_group=${TARGET_ENV}${COMMON_GROUP}${GROUP_SUFFIX}
k8_group=${TARGET_ENV}${K8_GROUP}${GROUP_SUFFIX}

output=$(truffle migrate --network k8sdev --reset)
CONTRACT_ADDRESS=$(echo "$output" | grep '^KauriCore address:' | sed 's/KauriCore address: //')
MODERATOR_CONTRACT_ADDRESS=$(echo "$output" | grep '^TopicModerator address:' | sed 's/TopicModerator address: //')
echo KuariCore Contract Address: $CONTRACT_ADDRESS
echo TopicModerator Contract Address: $MODERATOR_CONTRACT_ADDRESS

if [ -n "$(kubectl get secret smart-contract-addresses --ignore-not-found)" ]; then
  kubectl delete secret smart-contract-addresses
fi

kubectl create secret generic smart-contract-addresses \
                                                --namespace=${TARGET_ENV} \
                                                --from-literal=KuariCoreContractAddress=$CONTRACT_ADDRESS \
                                                --from-literal=ModeratorContractAddress=$MODERATOR_CONTRACT_ADDRESS
