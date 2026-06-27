#!/usr/bin/env bash

set -euo pipefail

echo "==> Configuring Docker"

sudo usermod -aG docker "$USER"

sudo systemctl enable --now docker

echo "==> Docker configured"

echo
echo "Logout/login required for docker group changes"