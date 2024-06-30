
# Setup cert-manager on Kubernetes cluster

This project sets up cert-manager in a Kubernetes cluster to manage TLS certificates and verifies the setup by deploying a test pod.

## Prerequisites

- Kubernetes cluster
- kubectl configured to access your cluster

## Steps to Setup cert-manager

### 1. Install cert-manager

Install cert-manager using the following command:

```sh
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml
```

Verify the installation:

```sh
kubectl get pods --namespace cert-manager
```

### 2. Create an Issuer

Create an Issuer using `issuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: webhook-selfsigned-issuer
  namespace: webhook
spec:
  selfSigned: {}
```

Apply the Issuer:

```sh
kubectl apply -f issuer.yaml
```

Verify the Issuer:

```sh
kubectl get issuer -n webhook
```

### 3. Create a Certificate

Create a Certificate using `certificate.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: webhook-tls
  namespace: webhook
spec:
  commonName: webhook.webhook.svc
  dnsNames:
    - webhook.webhook.svc
  secretName: webhook-tls
  issuerRef:
    name: webhook-selfsigned-issuer
```

Apply the Certificate:

```sh
kubectl apply -f certificate.yaml
```

Verify the Certificate:

```sh
kubectl get certificate -n webhook
```

### 4. Deploy a Test Pod

Deploy a test pod using `test-pod.yaml` to verify the certificate:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: webhook
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: tls
      mountPath: /tls
      readOnly: true
  volumes:
  - name: tls
    secret:
      secretName: webhook-tls
```

Apply the test pod:

```sh
kubectl apply -f test-pod.yaml
```

Verify the test pod:

```sh
kubectl exec -it test-pod -n webhook -- ls /tls
```

Check the pod logs:

```sh
kubectl logs test-pod -n webhook
```

### Cleanup

Delete the test pod:

```sh
kubectl delete pod test-pod -n webhook
```

### Automation Script

You can use the provided `setup-cert-manager.sh` script to automate all the steps:

```sh
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

echo "cert-manager setup and verification completed successfully."
```

Run the script:

```sh
chmod +x setup-cert-manager.sh
./setup-cert-manager.sh
```
