#!/usr/bin/env bash
# docker.sh
set -euo pipefail

echo "==> Configuring Docker"

sudo usermod -aG docker "$USER"

sudo systemctl enable --now docker
sudo systemctl enable docker.socket
sudo systemctl disable docker.service

echo "==> Docker configured"

echo
echo "Logout/login required for docker group changes"