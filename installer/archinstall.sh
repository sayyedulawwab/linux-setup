#!/usr/bin/env bash
# archinstall.sh
source ./utils.sh

########################################
# Helpers
########################################

cleanup() {
  warn "Cleaning up mounted filesystems..."
  umount -R /mnt 2>/dev/null || true
}

########################################
# Auto-cleanup on failure
########################################
trap 'warn "Unexpected error, cleaning up..."; cleanup' ERR

########################################
# Internet
########################################
info "Checking internet connection"
ping -c 1 archlinux.org &>/dev/null || error "No internet connection"

# Modify pacman config

sed -i 's/^#Color/Color/' /etc/pacman.conf

########################################
# Time sync
########################################
timedatectl set-ntp true

########################################
# Disk selection
########################################
lsblk
read -rp "Enter disk (default /dev/sda): " DISK_NAME
DISK_NAME=${DISK_NAME:-/dev/sda}
[[ -b "$DISK_NAME" ]] || error "Invalid disk: $DISK_NAME"

DISK_SIZE_BYTES=$(blockdev --getsize64 "$DISK_NAME")
DISK_SIZE_HUMAN=$(lsblk -dn -o SIZE "$DISK_NAME")

########################################
# Size prompts
########################################
echo
info "Selected disk: $DISK_NAME ($DISK_SIZE_HUMAN)"

read -rp "EFI size (default 2G): " EFI_SIZE
EFI_SIZE=${EFI_SIZE:-2G}

read -rp "Root size (e.g. 200G or fixed size, default 200G): " ROOT_SIZE
ROOT_SIZE=${ROOT_SIZE:-200G}

########################################
# Partitions
########################################
if [[ "$DISK_NAME" == *"nvme"* ]]; then
  EFI_PART="${DISK_NAME}p1"
  ROOT_PART="${DISK_NAME}p2"
  HOME_PART="${DISK_NAME}p3"
else
  EFI_PART="${DISK_NAME}1"
  ROOT_PART="${DISK_NAME}2"
  HOME_PART="${DISK_NAME}3"
fi

########################################
# Calculate partition boundaries
########################################

EFI_END="$EFI_SIZE"

ROOT_START="$EFI_END"

EFI_SIZE_NUM=${EFI_SIZE%G}
ROOT_SIZE_NUM=${ROOT_SIZE%G}

ROOT_END_HUMAN="$((EFI_SIZE_NUM + ROOT_SIZE_NUM))GiB"

########################################
# Disk wipe
########################################
info "Clearing existing mounts"
cleanup

mount | grep -q "^$DISK_NAME" && error "Disk appears mounted"

info "Wiping disk signatures"
wipefs -af $DISK_NAME

sgdisk --zap-all $DISK_NAME

########################################
# Partitioning
########################################
info "Partitioning disk"

parted -s -a optimal $DISK_NAME mklabel gpt

# EFI
parted -s -a optimal $DISK_NAME mkpart ESP fat32 1MiB $EFI_END
parted -s -a optimal $DISK_NAME set 1 esp on

# Root
parted -s -a optimal $DISK_NAME mkpart primary ext4 $ROOT_START $ROOT_END_HUMAN

# Home
parted -s -a optimal $DISK_NAME mkpart primary ext4 $ROOT_END_HUMAN 100%

partprobe $DISK_NAME
sleep 2

########################################
# Filesystems
########################################
mkfs.fat -F32 $EFI_PART
mkfs.ext4 $ROOT_PART
mkfs.ext4 $HOME_PART

########################################
# Mounting
########################################
mount $ROOT_PART /mnt

mkdir -p /mnt/home
mount $HOME_PART /mnt/home

mkdir -p /mnt/boot
mount $EFI_PART /mnt/boot

########################################
# Base install
########################################
info "Installing base system with pacstrap"
pacman -Sy
pacstrap -K /mnt base linux linux-firmware sof-firmware intel-ucode base-devel networkmanager sudo limine

info "Base system installed with pacstrap"

########################################
# fstab
########################################
genfstab -U /mnt > /mnt/etc/fstab

########################################
# Chroot setup
########################################
cp ./*.sh /mnt/
chmod +x /mnt/chroot.sh
arch-chroot /mnt /chroot.sh $DISK_NAME

########################################
# Cleanup
########################################
cleanup

########################################
# Finish
########################################
info "Installation completed successfully"
warn "Log saved at $LOG_FILE"
confirm "Reboot now?" && reboot
