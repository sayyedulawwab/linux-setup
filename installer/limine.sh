#!/usr/bin/env bash
# limine.sh

set -euo pipefail

DISK=$1
ROOT_PART=$2

ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")

mkdir -p /boot/EFI/BOOT

# Install Limine UEFI executable
cp /usr/share/limine/BOOTX64.EFI \
   /boot/EFI/BOOT/BOOTX64.EFI

# Create UEFI boot entry
efibootmgr \
    --create \
    --disk "$DISK" \
    --part 1 \
    --label "Arch Linux" \
    --loader '\EFI\BOOT\BOOTX64.EFI'

# Detect microcode image
MICROCODE=""

if [[ -f /boot/intel-ucode.img ]]; then
    MICROCODE="intel-ucode.img"
elif [[ -f /boot/amd-ucode.img ]]; then
    MICROCODE="amd-ucode.img"
fi

# Generate Limine configuration
cat > /boot/limine.conf <<EOF
TIMEOUT=5
DEFAULT_ENTRY=0

/Arch Linux

    protocol: linux
    path: boot():/vmlinuz-linux
    cmdline: root=UUID=${ROOT_UUID} rw quiet loglevel=3
EOF

# Microcode first if present
if [[ -n "$MICROCODE" ]]; then
cat >> /boot/limine.conf <<EOF
    MODULE_PATH: boot():/${MICROCODE}
EOF
fi

# Initramfs second
cat >> /boot/limine.conf <<EOF
    MODULE_PATH: boot():/initramfs-linux.img
EOF

echo
echo "Generated Limine configuration:"
echo "--------------------------------"
cat /boot/limine.conf
echo "--------------------------------"