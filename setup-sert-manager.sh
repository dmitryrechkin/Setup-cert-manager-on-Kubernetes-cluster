#!/bin/bash

set -e

# Step 1: Install cert-manager
echo "Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml

# Wait for cert-manager to be ready
echo "Waiting for cert-manager to be ready..."
kubectl wait --namespace cert-manager --for=condition=available --timeout=600s deployment/cert-manager
kubectl wait --namespace cert-manager --for=condition=available --timeout=600s deployment/cert-manager-webhook
kubectl wait --namespace cert-manager --for=condition=available --timeout=600s deployment/cert-manager-cainjector

# Step 2: Create namespace for the webhook
echo "Creating namespace 'webhook'..."
kubectl create namespace webhook || true

# Step 3: Apply Issuer
echo "Applying issuer..."
kubectl apply -f issuer.yaml

# Step 4: Apply Certificate
echo "Applying certificate..."
kubectl apply -f certificate.yaml

# Step 5: Apply test pod
echo "Applying test pod..."
kubectl apply -f test-pod.yaml

# Step 6: Verify test pod
echo "Verifying test pod..."
kubectl exec -it test-pod -n webhook -- ls /tls
kubectl logs test-pod -n webhook

# Setp 7: Delete test pod
kubectl delete pod test-pod -n webhook

echo "cert-manager setup and verification completed successfully."
