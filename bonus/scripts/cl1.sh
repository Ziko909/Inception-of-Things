#!/bin/bash
set -e

echo "🚀 Starting GitLab cleanup..."

# 1. Delete Helm release
helm uninstall gitlab -n gitlab 2>/dev/null || echo "Helm release not found"

# 2. Fast-delete namespace
echo "➔ Force-deleting namespace..."
kubectl delete namespace gitlab --wait=false 2>/dev/null || echo "Namespace not found"

# 3. Verify cleanup
echo "➔ Verifying resources..."
while kubectl get namespace gitlab 2>/dev/null; do
  echo "Waiting for namespace termination..."
  sleep 5
done

echo "✅ GitLab cleanup complete!"
