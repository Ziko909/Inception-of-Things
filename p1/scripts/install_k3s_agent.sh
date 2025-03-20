#!/bin/bash

echo "[Agent] Installing required packages..."
apt-get update -y
apt-get install -y curl

echo "[Agent] Waiting for token file from server..."
while [ ! -f /vagrant/token ]; do
  echo "[Agent] Token not found yet, retrying in 2s..."
  sleep 2
done

K3S_TOKEN=$(cat /vagrant/token)

echo "[Agent] Installing K3s agent..."
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$K3S_TOKEN sh -s - agent --node-name zaabouSW
