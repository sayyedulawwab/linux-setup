#!/usr/bin/env bash
set -euo pipefail

echo "==> Optimizing NetworkManager boot"

sudo systemctl disable NetworkManager-wait-online.service 2>/dev/null || true

echo "==> Done"