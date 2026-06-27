#!/usr/bin/env bash
# archinstall.sh
source ./utils.sh

########################################
# Installation Configuration
########################################

echo
info "Available disks:"
lsblk -d -o NAME,SIZE,MODEL

echo
read -rp "Disk to install to (example: /dev/nvme0n1): " DISK
[[ -b "$DISK" ]] || error "Invalid disk"

read -rp "Hostname: " HOSTNAME
read -rp "Username: " USERNAME

read -rp "Timezone [Asia/Dhaka]: " TIMEZONE
TIMEZONE=${TIMEZONE:-Asia/Dhaka}

read -rp "Locale [en_US.UTF-8]: " LOCALE
LOCALE=${LOCALE:-en_US.UTF-8}

read -rp "EFI size [2G]: " EFI_SIZE
EFI_SIZE=${EFI_SIZE:-2G}

read -rp "Root size [200G]: " ROOT_SIZE
ROOT_SIZE=${ROOT_SIZE:-200G}

echo
read -rsp "Root password: " ROOT_PASSWORD
echo

read -rsp "User password: " USER_PASSWORD
echo

echo
warn "Installation Summary"

cat <<EOF
Disk:         $DISK
Hostname:     $HOSTNAME
Username:     $USERNAME
Timezone:     $TIMEZONE
Locale:       $LOCALE
EFI Size:     $EFI_SIZE
Root Size:    $ROOT_SIZE
EOF

echo
confirm "Continue?" || exit 0

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
trap cleanup EXIT
trap 'error "Installation failed"' ERR


DEFAULT_EFI_SIZE="2G"
DEFAULT_ROOT_SIZE="200G"
DEFAULT_TZ="Asia/Dhaka"

########################################
# Internet
########################################
info "Checking internet connection"
ping -c 1 archlinux.org &>/dev/null || error "No internet connection"

# Modify pacman config
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 6/' /etc/pacman.conf

########################################
# Time sync
########################################
timedatectl set-ntp true


pacman -Sy
pacman -Sy reflector

reflector \
  --country Bangladesh,Singapore \
  --protocol https \
  --latest 20 \
  --sort rate \
  --save /etc/pacman.d/mirrorlist

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

if grep -qi intel /proc/cpuinfo; then
    CPU_UCODE="intel-ucode"
else
    CPU_UCODE="amd-ucode"
fi

pacstrap -K /mnt base linux linux-firmware sof-firmware "$CPU_UCODE" base-devel networkmanager sudo limine git vim zsh

info "Base system installed with pacstrap"

########################################
# fstab
########################################
genfstab -U /mnt > /mnt/etc/fstab

########################################
# Chroot setup
########################################
install -m755 ./*.sh /mnt/
arch-chroot /mnt /chroot.sh \
    "$DISK" \
    "$ROOT_PART" \
    "$HOSTNAME" \
    "$USERNAME" \
    "$TIMEZONE" \
    "$LOCALE" \
    "$ROOT_PASSWORD" \
    "$USER_PASSWORD"

########################################
# Finish
########################################
info "Installation completed successfully"
warn "Log saved at $LOG_FILE"
confirm "Reboot now?" && reboot
