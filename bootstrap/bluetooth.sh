#!/usr/bin/env bash
set -euo pipefail

echo "==> Configuring Bluetooth"

sudo systemctl enable --now bluetooth

echo "==> Bluetooth enabled"