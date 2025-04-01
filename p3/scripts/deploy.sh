#!/bin/bash
set -ex

# Apply Argo CD application definition
kubectl apply -f ../confs/argocd/application.yaml

# Verify sync status
echo "Waiting for Argo CD to sync..."
until kubectl get application playground-app -n argocd -o jsonpath='{.status.sync.status}' | grep -q "Synced"; do
  sleep 5
done
