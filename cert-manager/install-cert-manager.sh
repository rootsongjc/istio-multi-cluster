#!/bin/bash
set -e

# Cert-manager version to use
CERT_MANAGER_VERSION="v1.15.1"

echo "==== Starting cert-manager installation ===="

# Check and create the cert-manager namespace if it doesn't exist
if ! kubectl get namespace cert-manager >/dev/null 2>&1; then
    echo "Creating namespace cert-manager..."
    kubectl create namespace cert-manager
fi

echo "Installing cert-manager CRDs..."
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.crds.yaml

echo "Installing cert-manager components..."
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml

echo "Waiting for cert-manager components to start..."
kubectl -n cert-manager rollout status deploy/cert-manager --timeout=120s
kubectl -n cert-manager rollout status deploy/cert-manager-webhook --timeout=120s
kubectl -n cert-manager rollout status deploy/cert-manager-cainjector --timeout=120s

echo "==== Installing self-signed root CA ===="
kubectl apply -f ./selfsigned-root-ca.yaml

echo "==== Installing Istio CA certificate ===="
kubectl apply -f ./istio-ca.yaml

echo "==== Applying certificate rotation configuration ===="
kubectl apply -f ./cert-rotation.yaml

echo "Cert-Manager installation and configuration completed."
