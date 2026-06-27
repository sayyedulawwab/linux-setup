#!/usr/bin/env bash

set -euo pipefail

echo "==> Installing NVIDIA packages"

sudo pacman -S \
    --needed \
    --noconfirm \
    linux-headers \
    nvidia-open-dkms \
    nvidia-utils \
    nvidia-settings \
    egl-wayland

echo "==> Configuring NVIDIA DRM"

sudo mkdir -p /etc/modprobe.d

cat <<EOF | sudo tee /etc/modprobe.d/nvidia.conf
options nvidia_drm modeset=1
EOF

echo "==> Rebuilding initramfs"

sudo mkinitcpio -P