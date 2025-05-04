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
k3d cluster create gitlab-cluster \
  --servers 1 \
  --agents 2 \
  --port "30010:30010@loadbalancer" \
  --port "30011:30011@loadbalancer" \
  --wait

# Create namespace
kubectl create namespace gitlab || true

# Install Helm
if ! command -v helm &> /dev/null; then
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
fi

# Add GitLab chart repo
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# Install GitLab via Helm
helm install gitlab gitlab/gitlab -n gitlab -f ../confs/gitlab-values.yaml

# Apply custom ingress
kubectl apply -n gitlab -f ../confs/gitlab-ingress.yaml

# Wait for GitLab
echo -e "\nWaiting for GitLab pods to start..."
for i in {1..100}; do
  ready_pods=$(kubectl get pods -n gitlab --field-selector=status.phase=Running --no-headers | wc -l)
  if [[ "$ready_pods" -ge 2 ]]; then
    echo "GitLab is ready!"
    break
  fi
  sleep 15
done

# Display access info
echo "Visit http://<YOUR_VM_PUBLIC_IP>:30010 (or http://gitlab.local if hosts are set)"
echo -n "Root password: "
kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 --decode || echo "Not available yet"

EONG
