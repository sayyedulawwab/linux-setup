#!/usr/bin/env bash

DISK=$1
ROOT_PART=$2

ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")

mkdir -p /boot/EFI/BOOT

cp /usr/share/limine/BOOTX64.EFI \
   /boot/EFI/BOOT/BOOTX64.EFI

efibootmgr \
  --create \
  --disk "$DISK" \
  --part 1 \
  --label "Arch Linux" \
  --loader '\EFI\BOOT\BOOTX64.EFI'

MICROCODE=$(ls /boot/*-ucode.img | xargs basename)

cat >/boot/limine.conf <<EOF
TIMEOUT=5
DEFAULT_ENTRY=0

:Arch Linux

PROTOCOL=linux
KERNEL_PATH=boot():/vmlinuz-linux
CMDLINE=root=UUID=${ROOT_UUID} rw

MODULE_PATH=boot():/${MICROCODE}
MODULE_PATH=boot():/initramfs-linux.img
EOF