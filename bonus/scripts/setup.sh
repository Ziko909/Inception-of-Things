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
  --port "30010:30010@loadbalancer" \  # Map host 30010 → k3d loadbalancer 30010
  --port "30011:30011@loadbalancer" \
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

# Install Helm if not present
if ! command -v helm &> /dev/null; then
  echo "Installing Helm..."
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
fi

# Configure GitLab Helm repository
helm repo add gitlab https://charts.gitlab.io/ || { echo "Failed to add GitLab repo"; exit 1; }
helm repo update

# Create namespace
kubectl create namespace gitlab 2>/dev/null || true

# Install minimal GitLab with ALL object storage disabled
helm install gitlab gitlab/gitlab -n gitlab -f ../confs/gitlab-values.yaml

kubectl apply -n gitlab -f ../confs/gitlab-ingress.yaml

# Wait for GitLab to be ready
echo -e "\nWaiting for GitLab to start (this may take 15-20 minutes)..."
for i in {1..80}; do
  ready_pods=$(kubectl get pods -n gitlab --field-selector=status.phase=Running --no-headers | wc -l)
  if [[ "$ready_pods" -ge 2 ]]; then
    echo "GitLab pods are ready!"
    break
  fi
  echo -n "."
  sleep 15
done

# Display access information
echo -e "\nGitLab Access Information:"
echo "GitLab should be available at: http://localhost:30010"
echo -n "Root password: "
kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 --decode 2>/dev/null || \
  echo -e "\nPassword not available yet. Try again in a few minutes."