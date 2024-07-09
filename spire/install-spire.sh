#/bin/bash

set -e

export CTX_CLUSTER1=cluster-1
export CTX_CLUSTER2=cluster-2

# Install Spire on foo cluster
kubectl apply -f ./spire/configmaps.yaml -f ./spire/foo-spire.yaml --context="${CTX_CLUSTER1}"
spire_bundle_endpoint_foo=$(kubectl get svc spire-server-bundle-endpoint --context="${CTX_CLUSTER1}" -n spire -o jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports[0].port}')

# Install Spire on bar cluster
kubectl apply -f ./spire/configmaps.yaml -f ./spire/bar-spire.yaml --context="${CTX_CLUSTER2}"
spire_bundle_endpoint_bar=$(kubectl get svc spire-server-bundle-endpoint --context="${CTX_CLUSTER2}" -n spire -o jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports[0].port}')

# Restart Spire foo
cat ./spire/foo-spire.yaml | sed "s/<spire_bundle_endpoint_bar>/$spire_bundle_endpoint_bar/g" | kubectl apply -f - --context="${CTX_CLUSTER1}"
kubectl -n spire rollout status statefulset spire-server --context="${CTX_CLUSTER1}"
kubectl -n spire rollout status daemonset spire-agent --context="${CTX_CLUSTER1}"
foo_bundle=$(kubectl exec --context="${CTX_CLUSTER1}" -c spire-server -n spire --stdin spire-server-0  -- /opt/spire/bin/spire-server bundle show -format spiffe -socketPath /run/spire/sockets/server.sock)

# Restart Spire bar
cat ./spire/bar-spire.yaml | sed "s/<spire_bundle_endpoint_foo>/$spire_bundle_endpoint_foo/g" | kubectl apply -f - --context="${CTX_CLUSTER2}"
kubectl -n spire rollout status statefulset spire-server --context="${CTX_CLUSTER2}"
kubectl -n spire rollout status daemonset spire-agent --context="${CTX_CLUSTER2}"
bar_bundle=$(kubectl exec --context="${CTX_CLUSTER2}" -c spire-server -n spire --stdin spire-server-0 -- /opt/spire/bin/spire-server bundle show -format spiffe -socketPath /run/spire/sockets/server.sock)

# Set foo.com bundle to bar.com SPIRE bundle endpoint
kubectl exec --context="${CTX_CLUSTER2}" -c spire-server -n spire --stdin spire-server-0 \
  -- /opt/spire/bin/spire-server bundle set -format spiffe -id spiffe://foo.com -socketPath /run/spire/sockets/server.sock <<< "$foo_bundle"

# Set bar.com bundle to foo.com SPIRE bundle endpoint
kubectl exec --context="${CTX_CLUSTER1}" -c spire-server -n spire --stdin spire-server-0 \
  -- /opt/spire/bin/spire-server bundle set -format spiffe -id spiffe://bar.com -socketPath /run/spire/sockets/server.sock <<< "$bar_bundle"