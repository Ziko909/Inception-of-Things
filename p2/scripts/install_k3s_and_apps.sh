#!/bin/bash
set -e

apt-get update
apt-get install -y curl

curl -sfL https://get.k3s.io | sh -

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "[INFO] Waiting for K3s to start..."
sleep 10

# Apply ConfigMaps (HTML content)
kubectl apply -f /vagrant/confs/app1-configmap.yaml
kubectl apply -f /vagrant/confs/app2-configmap.yaml
kubectl apply -f /vagrant/confs/app3-configmap.yaml

# Apply Deployments and Services
kubectl apply -f /vagrant/confs/app1-deployment.yaml
kubectl apply -f /vagrant/confs/app1-service.yaml

kubectl apply -f /vagrant/confs/app2-deployment.yaml
kubectl apply -f /vagrant/confs/app2-service.yaml

kubectl apply -f /vagrant/confs/app3-deployment.yaml
kubectl apply -f /vagrant/confs/app3-service.yaml

# Apply Ingress rules
kubectl apply -f /vagrant/confs/ingress.yaml
