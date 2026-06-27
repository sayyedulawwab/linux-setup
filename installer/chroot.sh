#!/usr/bin/env bash
# chroot.sh
source ./utils.sh

DISK_NAME=$1

########################################
# Timezone
########################################
read -rp "Timezone (default Asia/Dhaka): " TZ
TZ=${TZ:-Asia/Dhaka}
ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
hwclock --systohc

########################################
# Locale
########################################
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

########################################
# Hostname
########################################
read -rp "Hostname: " HOSTNAME

echo "$HOSTNAME" > /etc/hostname

echo "127.0.0.1 localhost" >/etc/hosts
echo "::1 localhost" >>/etc/hosts
echo "127.0.1.1 $HOSTNAME" >>/etc/hosts

########################################
# Root password
########################################
echo "Set root password"
passwd

########################################
# User
########################################
read -rp "Username: " USERNAME
useradd -m -G wheel -s /bin/bash $USERNAME
echo "Set password for $USERNAME"
passwd "$USERNAME"

########################################
# Sudo
########################################
pacman -S --noconfirm sudo
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/00-wheel
chmod 440 /etc/sudoers.d/00-wheel

########################################
# NetworkManager
########################################
systemctl enable NetworkManager

source limine.sh "$DISK"

mkinitcpio -P