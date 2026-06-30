#!/usr/bin/env bash
# limine.sh
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

if [[ -f /boot/intel-ucode.img ]]; then
    MICROCODE=intel-ucode.img
elif [[ -f /boot/amd-ucode.img ]]; then
    MICROCODE=amd-ucode.img
else
    MICROCODE=
fi

cat >/boot/limine.conf <<EOF
TIMEOUT=5
DEFAULT_ENTRY=0

:Arch Linux

PROTOCOL=linux
KERNEL_PATH=boot():/vmlinuz-linux
CMDLINE=root=UUID=${ROOT_UUID} rw quiet loglevel=3

MODULE_PATH=boot():/${MICROCODE}
MODULE_PATH=boot():/initramfs-linux.img
EOF