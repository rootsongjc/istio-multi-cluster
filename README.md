# Multi-Cluster Istio Service Mesh with Spiffe/SPIRE Federation

This guide provides instructions for setting up a multi-cluster Istio service mesh with Spiffe/SPIRE federation to manage identities across multiple Kubernetes clusters.

## Acknowledgment

This project is inspired by the [Istio Service Mesh with Spiffe/SPIRE Federation between EKS clusters](https://github.com/aws-samples/istio-on-eks/tree/main/patterns/eks-istio-mesh-spire-federation). It reuses a significant amount of code from that example, which has been adapted to run on Google Kubernetes Engine (GKE). Additionally, the project can be easily deployed on other cloud platforms.

If you intend to run this project in a local environment, please adjust the SPIRE Server's service and SPIRE bundle endpoint configuration by changing from LoadBalancer to NodePort.

## Prerequisites

- Two Kubernetes clusters with the context names `cluster-1` and `cluster-2`.
- Each cluster must have at least 16 GB of memory.

### Component Versions

- Kubernetes: v1.29.4
- Istio: v1.22.1
- SPIRE: v1.5.1
- cert-manager: v1.15.1

**Note**: This project utilizes the [SPIRE Kubernetes Workload Registrar](https://istio.io/v1.17/docs/ops/integrations/spire/#create-federated-registration-entries) rather than the newer [SPIRE Controller Manager](https://istio.io/latest/docs/ops/integrations/spire/#create-federated-registration-entries). An attempt was made to implement SPIRE Federation using the SPIRE Controller Manager; however, issues were encountered with workload authentication during the setup of a multi-cluster Istio installation.

### Environment Setup

Set the Kubernetes contexts for the clusters:

```bash
export CTX_CLUSTER1=cluster-1
export CTX_CLUSTER2=cluster-2
```

## Installation Steps

### Cert-Manager Setup

Use cert-manager as the root CA to issue certificates for istiod and SPIRE.

```bash
./cert-manager/install-cert-manager.sh
```

### SPIRE Federation Setup

Utilize the provided [script](./spire/install-spire.sh) to automate the exchange of CA bundles necessary for federation. The script performs the following actions:

- Assigns `cert-manager` as the root CA with cluster-wide permissions by adding it as a clusterRole.
- Creates the namespace required for SPIRE components.
- Deploys SPIRE server and agent using Kubernetes manifests.
- Configures the trust domain (`foo.com` and `bar.com`) for the SPIRE server.
- Enables federation mode, allowing SPIRE servers to share their bundles with other trust domains securely.
- Exchanges trust bundles between clusters to facilitate cross-cluster communication.

```bash
./spire/install-spire.sh
```

### Istio Installation

Install Istio using the Istio Operator with the following script, which ensures the integration of SPIRE sidecars for automatic injection into application pods:

```bash
./istio/install-istio.sh
```

### Application Deployment

Deploy the `helloworld` application across both clusters (`cluster-1` and `cluster-2`) with separate deployments (`hello-world-v1` and `hello-world-v2` respectively) using the same Kubernetes service name "hello-world". A "sleep" deployment, serving as a test client, is also created in `cluster-1`.

```bash
./examples/deploy-helloworld.sh
```

## Verification

Verify the installation by checking the pods in both clusters:

```bash
kubectl get po -A --context="${CTX_CLUSTER1}"
kubectl get po -A --context="${CTX_CLUSTER2}"
```

You should see similar to below:

```bash
kubectl get po -A --context=cluster-1
NAMESPACE      NAME                                                  READY   STATUS    RESTARTS   AGE
cert-manager   cert-manager-5798486f6b-dzzvx                         1/1     Running   0          25h
cert-manager   cert-manager-cainjector-7666685ff5-r4pdp              1/1     Running   0          25h
cert-manager   cert-manager-webhook-5f594df789-skjxr                 1/1     Running   0          25h
gmp-system     collector-h7vz5                                       2/2     Running   0          2d17h
gmp-system     collector-j64wn                                       2/2     Running   0          2d16h
gmp-system     collector-v29d9                                       2/2     Running   0          2d17h
gmp-system     gmp-operator-6d499f7db4-h4tdf                         1/1     Running   0          2d17h
helloworld     helloworld-v1-6bb5b589d6-jq4gn                        2/2     Running   0          45m
istio-system   istio-eastwestgateway-85ff96845d-59mjm                1/1     Running   0          58m
istio-system   istio-ingressgateway-5696596bd-4dq7n                  1/1     Running   0          58m
istio-system   istiod-68cfb86dbc-flj48                               1/1     Running   0          58m
kube-system    event-exporter-gke-54d86d77bb-vn45d                   2/2     Running   0          2d17h
kube-system    fluentbit-gke-hhznv                                   3/3     Running   0          2d17h
kube-system    fluentbit-gke-nxq9k                                   3/3     Running   0          2d16h
kube-system    fluentbit-gke-r7q9b                                   3/3     Running   0          2d17h
kube-system    gke-metrics-agent-4sxh6                               3/3     Running   0          2d17h
kube-system    gke-metrics-agent-8m8q7                               3/3     Running   0          2d17h
kube-system    gke-metrics-agent-bw92x                               3/3     Running   0          2d16h
kube-system    konnectivity-agent-6674864566-grxbg                   2/2     Running   0          2d17h
kube-system    konnectivity-agent-6674864566-q5j5n                   2/2     Running   0          2d17h
kube-system    konnectivity-agent-6674864566-xgdj9                   2/2     Running   0          2d16h
kube-system    konnectivity-agent-autoscaler-79dff7f766-pkwkk        1/1     Running   0          2d17h
kube-system    kube-dns-786b4d4b5b-d5wj5                             5/5     Running   0          2d17h
kube-system    kube-dns-786b4d4b5b-n27wx                             5/5     Running   0          2d16h
kube-system    kube-dns-autoscaler-79b96f5cb-x6fsz                   1/1     Running   0          2d17h
kube-system    kube-proxy-gke-cluster-1-default-pool-18d66649-bu2x   1/1     Running   0          2d17h
kube-system    kube-proxy-gke-cluster-1-default-pool-18d66649-g4a2   1/1     Running   0          2d17h
kube-system    kube-proxy-gke-cluster-1-default-pool-18d66649-z1lm   1/1     Running   0          2d16h
kube-system    l7-default-backend-6dc96cd585-kmdnf                   1/1     Running   0          2d17h
kube-system    metrics-server-v0.7.0-dbcc8ddf6-wvhwt                 2/2     Running   0          2d16h
kube-system    pdcsi-node-4zhlt                                      2/2     Running   0          2d16h
kube-system    pdcsi-node-b5xct                                      2/2     Running   0          2d17h
kube-system    pdcsi-node-c9mwk                                      2/2     Running   0          2d17h
sleep          sleep-86bfc4d596-4jf87                                2/2     Running   0          35m
spire          spire-agent-b9s46                                     3/3     Running   0          62m
spire          spire-agent-lfgvk                                     3/3     Running   0          62m
spire          spire-agent-mtj46                                     3/3     Running   0          62m
spire          spire-server-0                                        2/2     Running   0          62m
kubectl get po -A --context=cluster-2
NAMESPACE      NAME                                                  READY   STATUS    RESTARTS   AGE
cert-manager   cert-manager-5798486f6b-l27f8                         1/1     Running   0          22h
cert-manager   cert-manager-cainjector-7666685ff5-zcbc2              1/1     Running   0          22h
cert-manager   cert-manager-webhook-5f594df789-bcnnv                 1/1     Running   0          22h
default        details-v1-5b66cccddb-wqjwd                           2/2     Running   0          5h42m
default        productpage-v1-f8c54768c-r8b5t                        2/2     Running   0          5h42m
default        ratings-v1-575d5c649d-7wfp9                           2/2     Running   0          5h42m
default        reviews-v1-5f6584cc9c-8bqhf                           2/2     Running   0          5h42m
default        reviews-v2-55f6cdbd8b-4s6hd                           2/2     Running   0          5h42m
default        reviews-v3-5897696c5f-jzgq4                           2/2     Running   0          5h42m
gmp-system     collector-mr5f7                                       2/2     Running   0          3d10h
gmp-system     collector-wbh4g                                       2/2     Running   0          3d10h
gmp-system     collector-wv5c8                                       2/2     Running   0          3d10h
gmp-system     gmp-operator-5686755586-k95g5                         1/1     Running   0          3d10h
helloworld     helloworld-v2-7fd66fcfdc-6shtc                        0/2     Pending   0          47m
istio-system   istio-eastwestgateway-67b988559b-sz2lr                1/1     Running   0          59m
istio-system   istio-ingressgateway-76d58c497b-nd69q                 1/1     Running   0          59m
istio-system   istiod-787c7bf674-sb9w8                               1/1     Running   0          59m
kube-system    event-exporter-gke-54d86d77bb-v54bw                   2/2     Running   0          3d10h
kube-system    fluentbit-gke-ctssg                                   3/3     Running   0          3d10h
kube-system    fluentbit-gke-rr2mk                                   3/3     Running   0          3d10h
kube-system    fluentbit-gke-w6ppn                                   3/3     Running   0          3d10h
kube-system    gke-metrics-agent-6jz2c                               3/3     Running   0          3d10h
kube-system    gke-metrics-agent-jdkrf                               3/3     Running   0          3d10h
kube-system    gke-metrics-agent-rk4k5                               3/3     Running   0          3d10h
kube-system    konnectivity-agent-6899f46dd5-6d2xz                   2/2     Running   0          3d10h
kube-system    konnectivity-agent-6899f46dd5-7jrvt                   2/2     Running   0          3d10h
kube-system    konnectivity-agent-6899f46dd5-cljrk                   2/2     Running   0          3d10h
kube-system    konnectivity-agent-autoscaler-79dff7f766-4z4q6        1/1     Running   0          3d10h
kube-system    kube-dns-6c77995964-4jhpt                             5/5     Running   0          3d10h
kube-system    kube-dns-6c77995964-wbttg                             5/5     Running   0          3d10h
kube-system    kube-dns-autoscaler-79b96f5cb-f85ww                   1/1     Running   0          3d10h
kube-system    kube-proxy-gke-cluster-2-default-pool-4ace2a1c-4tze   1/1     Running   0          3d10h
kube-system    kube-proxy-gke-cluster-2-default-pool-4ace2a1c-fmw5   1/1     Running   0          3d10h
kube-system    kube-proxy-gke-cluster-2-default-pool-4ace2a1c-kic8   1/1     Running   0          3d10h
kube-system    l7-default-backend-6dc96cd585-75v5l                   1/1     Running   0          3d10h
kube-system    metrics-server-v0.7.0-dbcc8ddf6-kd6qg                 2/2     Running   0          3d10h
kube-system    pdcsi-node-qv5qz                                      2/2     Running   0          3d10h
kube-system    pdcsi-node-sbmwv                                      2/2     Running   0          3d10h
kube-system    pdcsi-node-sd4b5                                      2/2     Running   0          3d10h
sleep          sleep-64cbcc4cd9-zvmsx                                0/2     Pending   0          37m
spire          spire-agent-nh58l                                     3/3     Running   0          64m
spire          spire-agent-nx2jh                                     3/3     Running   0          64m
spire          spire-agent-p8lqv                                     3/3     Running   0          64m
spire          spire-server-0                                        2/2     Running   0          64m
```

### Verifying East-West Traffic Federation Between Clusters

To verify east-west gateway communication across clusters, execute a `curl` command from a "sleep" pod in `cluster-1` targeting the "hello-world" service. This command retrieves responses from both the "hello-world-v1" deployment in `cluster-1` and the "hello-world-v2" deployment in `cluster-2`. This setup demonstrates seamless cross-cluster communication facilitated by federated Spire identities, confirming that traffic flows freely across the federated clusters, enabling secure mTLS communication between workloads originating from different clusters with different root CAs.

```bash
kubectl exec --context="${CTX_CLUSTER1}" -n sleep -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sleep -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- sh -c "while :; do curl -sS helloworld.helloworld:5000/hello; sleep 1; done"
```

Expected output:

```bash
Hello version: v1, instance: helloworld-v1-6bb5b589d6-jq4gn
Hello version: v2, instance: helloworld-v2-7fd66fcfdc-6shtc
(repeated)
```

### Verifying North-South Traffic Federation Between Clusters

Initially, both the "hello-world-v1" in `cluster-1` and "hello-world-v2" in `cluster-2` are operational. Scale down the "hello-world-v1" deployment in `cluster-1` to zero, effectively stopping all its pods. Subsequently, configure a Gateway and a Virtual Service in `cluster-2` for the "hello-world-v2" deployment to manage ingress traffic via an Istio Gateway, which acts as a load balancer. This setup directs traffic to the "hello-world-v2" service from outside the mesh (from `cluster-1`).

```bash
kubectl -n helloworld scale deploy helloworld-v1 --context="${CTX_CLUSTER1}" --replicas 0

sleep 2

kubectl apply --context="${CTX_CLUSTER2}" \
    -f ./examples/helloworld-gateway.yaml -n helloworld

export INGRESS_NAME=istio-ingressgateway
export INGRESS_NS=istio-system
GATEWAY_URL=$(kubectl -n "$INGRESS_NS" --context="${CTX_CLUSTER2}" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

Validate the setup by curling the Gateway URL from the `cluster-1` sleep pod:

```bash
kubectl exec --context="${CTX_CLUSTER1}" -n sleep -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sleep -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- sh -c "while :; do curl -s http://$GATEWAY_URL/hello; sleep 1; done"
```

Expected output:

```bash
Hello version: v2, instance: helloworld-v2-7fd66fcfdc-6shtc
(repeated)
```

### Viewing the Certificate Trust Chain

To illustrate the roles of the Root CA and intermediate CA within our configuration, we deploy the "Bookinfo" application. Here, `cert-manager` serves as the Root CA, and Spiffe acts as the intermediate CA, responsible for issuing workload identities and certificates.

#### Deploying the Bookinfo Application

Execute the following script to deploy the "Bookinfo" application:

```bash
./examples/deploy-bookinfo.sh
```

This script checks the identities issued by Spiffe to the workloads:

```bash
kubectl exec -i -t -n spire -c spire-server \
  "$(kubectl get pod -n spire -l app=spire-server -o jsonpath='{.items[0].metadata.name}')" \
  -- ./bin/spire-server entry show -socketPath /run/spire/sockets/server.sock
```

#### Examining the Certificate Trust Chain for the Productpage Pod

To view the certificate trust chain for the `productpage` pod, retrieve and decode the certificates as follows:

```bash
istioctl proxy-config secret deployment/productpage-v1 -o json | jq -r '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode > chain.pem
split -p "-----BEGIN CERTIFICATE-----" chain.pem cert-
```

List the split certificates:

```bash
ls cert-a*
```

Examine the root CA certificate (`cert-ab`), noting that `cert-manager` is the issuer:

```bash
openssl x509 -noout -text -in cert-ab
```

Inspect the intermediate CA certificate (`cert-aa`), observing Spiffe's role:

```bash
openssl x509 -noout -text -in cert-aa
```

## Setting Up Automatic Certificate Rotation

To modify the rotation period for Istiod's certificates from 60 days (1440 hours) to 30 days (720 hours), execute the following command:

```bash
kubectl -f ./cert-manager/cert-rotation.yaml --context $CTX_CLUSTER1
```

To verify the update, check the Istiod logs:

```bash
kubectl logs -l app=istiod -n istio-system -f
```

## Cleanup

Uninstall the samples, Istio, SPIRE and Cert-Manager from both clusters to clean up the environment:

```bash
./example/delete-helloworld.sh
./istio/cleanup-istio.sh
./spire/cleanup-spire.sh
./cert-manager/cleanup-cert-manager.sh
```