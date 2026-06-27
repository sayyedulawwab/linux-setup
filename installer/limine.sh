#!/usr/bin/env bash

DISK=$1

limine bios-install "$DISK" || true

mkdir -p /boot/EFI/BOOT

cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/

cp /usr/share/limine/limine.conf /boot/limine.conf