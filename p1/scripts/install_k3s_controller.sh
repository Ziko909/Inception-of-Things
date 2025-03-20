#!/bin/bash

echo "[Controller] Installing required packages..."
apt-get update -y
apt-get install -y curl

echo "[Controller] Installing K3s server..."
curl -sfL https://get.k3s.io | sh -s - server --node-ip=192.168.56.110

echo "[Controller] Waiting for K3s to generate token..."
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 1
done

echo "[Controller] Copying node token to /vagrant..."
cp /var/lib/rancher/k3s/server/node-token /vagrant/token
chmod 600 /vagrant/token
