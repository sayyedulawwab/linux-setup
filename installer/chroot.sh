#!/usr/bin/env bash
# chroot.sh
source ./utils.sh

DISK=$1
ROOT_PART=$2
HOSTNAME=$3
USERNAME=$4
TIMEZONE=$5
LOCALE=$6
ROOT_PASSWORD=$7
USER_PASSWORD=$8

########################################
# Timezone
########################################
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

########################################
# Locale
########################################
sed -i "s/^#${LOCALE} ${LOCALE#*.}/${LOCALE} ${LOCALE#*.}/" /etc/locale.gen

locale-gen

echo "LANG=$LOCALE" >/etc/locale.conf

########################################
# Hostname
########################################
echo "$HOSTNAME" >/etc/hostname

echo "127.0.0.1 localhost" >/etc/hosts
echo "::1 localhost" >>/etc/hosts
echo "127.0.1.1 $HOSTNAME" >>/etc/hosts

########################################
# Root password
########################################
echo "Set root password"
echo "root:$ROOT_PASSWORD" | chpasswd

########################################
# User
########################################
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

########################################
# Sudo
########################################
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/00-wheel
chmod 440 /etc/sudoers.d/00-wheel

########################################
# NetworkManager
########################################
systemctl enable NetworkManager

bash /limine.sh "$DISK" "$ROOT_PART"

mkinitcpio -P