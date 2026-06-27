#!/usr/bin/env bash

DISK=$1
ROOT_PART=$2

ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")

limine bios-install "$DISK" || true

mkdir -p /boot/EFI/BOOT

cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/
cp /usr/share/limine/limine.conf /boot/

if [[ -f /boot/intel-ucode.img ]]; then
    MICROCODE=intel-ucode.img
elif [[ -f /boot/amd-ucode.img ]]; then
    MICROCODE=amd-ucode.img
fi

cat >/boot/limine.conf <<EOF
TIMEOUT=5

:Arch Linux

PROTOCOL=linux
KERNEL_PATH=boot():/vmlinuz-linux
CMDLINE=root=UUID=${ROOT_UUID} rw
MODULE_PATH=boot():/initramfs-linux.img
MODULE_PATH=boot():/$MICROCODE
EOF