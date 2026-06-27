#!/usr/bin/env bash

source /utils.sh

DISK=$1
ROOT_PART=$2
HOSTNAME=$3
USERNAME=$4
TIMEZONE=$5
LOCALE=$6

ROOT_PASSWORD=$(cat /root-password)
USER_PASSWORD=$(cat /user-password)

ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime

hwclock --systohc

sed -i "s/^#${LOCALE} UTF-8/${LOCALE} UTF-8/" /etc/locale.gen

locale-gen

echo "LANG=$LOCALE" >/etc/locale.conf

echo "$HOSTNAME" >/etc/hostname

cat >/etc/hosts <<EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
EOF

echo "root:$ROOT_PASSWORD" | chpasswd

useradd -m -G wheel -s /bin/bash "$USERNAME"

echo "$USERNAME:$USER_PASSWORD" | chpasswd

echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >/etc/sudoers.d/00-wheel

chmod 440 /etc/sudoers.d/00-wheel

systemctl enable NetworkManager

bash /limine.sh "$DISK" "$ROOT_PART"

mkinitcpio -P

rm -f /root-password /user-password