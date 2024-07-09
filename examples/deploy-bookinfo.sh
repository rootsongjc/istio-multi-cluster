#/bin/bash

export CTX_CLUSTER2=cluster-2


kubectl config use-context ${CTX_CLUSTER2}

istioctl kube-inject -f ./examples/bookinfo-with-spire-template.yaml | kubectl apply -f -
sleep 6

echo " >>>Check whether SPIRE has issued an identity to the workload"

kubectl exec -i -t -n spire -c spire-server \
  "$(kubectl get pod -n spire -l app=spire-server -o jsonpath='{.items[0].metadata.name}')" \
  -- ./bin/spire-server entry show -socketPath /run/spire/sockets/server.sock