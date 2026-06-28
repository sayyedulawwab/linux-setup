#!/usr/bin/env bash
# nvidia.sh
set -euo pipefail

if ! lspci | grep -qi nvidia; then
    echo "No NVIDIA GPU detected."
    exit 0
fi

echo "==> Installing NVIDIA packages"

sudo pacman -S \
    --needed \
    --noconfirm \
    linux-headers \
    nvidia-open-dkms \
    nvidia-utils \
    nvidia-settings \
    egl-wayland \
    mesa \
    vulkan-icd-loader \
    libva-nvidia-driver \
    nvtop

echo "==> Configuring NVIDIA DRM"

sudo mkdir -p /etc/modprobe.d

cat <<EOF | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null
options nvidia_drm modeset=1
EOF

echo
echo "Add the following modules to /etc/mkinitcpio.conf if desired:"
echo
echo "nvidia nvidia_modeset nvidia_uvm nvidia_drm"
echo
echo "==> Rebuilding initramfs"
sudo mkinitcpio -P

echo "==> NVIDIA setup complete"
echo
echo "Remember to reboot."