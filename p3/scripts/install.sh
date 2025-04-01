#!/bin/bash
set -ex

# Install dependencies
sudo apt update && sudo apt install -y curl git docker.io

# Configure Docker
sudo usermod -aG docker $USER
newgrp docker <<EONG

# Install K3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/

# Create cluster
k3d cluster create iot-cluster \
  --servers 1 \
  --agents 2 \
  --port "8888:30080@loadbalancer" \
  --wait

# Create and label namespaces
kubectl create namespace dev || true
kubectl label namespace dev argocd.argoproj.io/managed-by=argocd

# Install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
until kubectl get secret argocd-initial-admin-secret -n argocd &>/dev/null; do
  sleep 5
done

# Get password (now guaranteed to exist)
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD Admin Password: $ARGOCD_PASSWORD" > ~/argocd-password.txt

# Configure access
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

EONG