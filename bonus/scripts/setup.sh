#!/bin/bash

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