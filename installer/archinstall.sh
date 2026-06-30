#!/usr/bin/env bash
# archinstall.sh
source ./utils.sh

SUCCESS=0

cleanup() {
    umount -R /mnt 2>/dev/null || true
}

trap '
if [[ $SUCCESS -eq 0 ]]; then
    cleanup
fi
' EXIT

trap 'error "Installation failed"' ERR

info "Available disks"

mapfile -t DISKS < <(
    lsblk -dpno NAME,SIZE,MODEL  | grep -v loop
)

for i in "${!DISKS[@]}"; do
    echo "$((i+1))) ${DISKS[$i]}"
done

read -rp "Select disk: " DISK_INDEX

DISK=$(echo "${DISKS[$((DISK_INDEX-1))]}" | awk '{print $1}')

[[ -b "$DISK" ]] || error "Invalid disk"

read -rp "Hostname: " HOSTNAME
read -rp "Username: " USERNAME

read -rp "Timezone [Asia/Dhaka]: " TIMEZONE
TIMEZONE=${TIMEZONE:-Asia/Dhaka}

read -rp "Locale [en_US.UTF-8]: " LOCALE
LOCALE=${LOCALE:-en_US.UTF-8}

read -rp "EFI Size [2G]: " EFI_SIZE
EFI_SIZE=${EFI_SIZE:-2G}

read -rp "Root Size [200G]: " ROOT_SIZE
ROOT_SIZE=${ROOT_SIZE:-200G}

echo
read -rsp "Root Password: " ROOT_PASSWORD
echo

read -rsp "User Password: " USER_PASSWORD
echo

cat <<EOF

Disk:      $DISK
Hostname:  $HOSTNAME
Username:  $USERNAME
Timezone:  $TIMEZONE
Locale:    $LOCALE
EFI Size:  $EFI_SIZE
Root Size: $ROOT_SIZE

EOF

confirm "Continue?" || exit 0

step "Checking internet"

ping -c 1 archlinux.org >/dev/null || error "No internet"

[[ -d /sys/firmware/efi ]] || error "System not booted in UEFI mode"

timedatectl set-ntp true

sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i '/^#VerbosePkgLists/s/^#//' /etc/pacman.conf
sed -i '/^#ParallelDownloads/s/^#//' /etc/pacman.conf
sed -i 's/^ParallelDownloads.*/ParallelDownloads = 6/' /etc/pacman.conf
sed -i '/^#ILoveCandy/s/^#//' /etc/pacman.conf

grep -q '^Color' /etc/pacman.conf || \
    echo "Color" >> /etc/pacman.conf

pacman -S --noconfirm --needed reflector

step "Refreshing mirrorlist"
reflector \
  --country Bangladesh,Singapore \
  --protocol https \
  --latest 20 \
  --sort rate \
  --save /etc/pacman.d/mirrorlist

if [[ "$DISK" == *"nvme"* ]]; then
    EFI_PART="${DISK}p1"
    ROOT_PART="${DISK}p2"
    HOME_PART="${DISK}p3"
else
    EFI_PART="${DISK}1"
    ROOT_PART="${DISK}2"
    HOME_PART="${DISK}3"
fi

EFI_SIZE_NUM=${EFI_SIZE%G}
ROOT_SIZE_NUM=${ROOT_SIZE%G}

ROOT_END="$((EFI_SIZE_NUM + ROOT_SIZE_NUM))GiB"

info "Unmounting previous mounts"

cleanup

warn "ALL DATA ON $DISK WILL BE LOST"
confirm "Continue with disk wipe?" || exit 1

info "Wiping disk"

wipefs -af "$DISK"
sgdisk --zap-all "$DISK"

step "Partitioning disk"

parted -s "$DISK" mklabel gpt

parted -s "$DISK" mkpart ESP fat32 1MiB "$EFI_SIZE"
parted -s "$DISK" set 1 esp on

parted -s "$DISK" mkpart primary ext4 "$EFI_SIZE" "$ROOT_END"

parted -s "$DISK" mkpart primary ext4 "$ROOT_END" 100%

udevadm settle

step "Formatting partitions"

mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 -F "$ROOT_PART"
mkfs.ext4 -F "$HOME_PART"

info "Mounting"

mount "$ROOT_PART" /mnt

mkdir -p /mnt/home
mount "$HOME_PART" /mnt/home

mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

if grep -qi intel /proc/cpuinfo; then
    CPU_UCODE=intel-ucode
else
    CPU_UCODE=amd-ucode
fi

step "Installing base system"

pacstrap -K /mnt \
    base \
    linux \
    linux-firmware \
    sof-firmware \
    "$CPU_UCODE" \
    base-devel \
    networkmanager \
    sudo \
    git \
    vim \
    zsh \
    curl \
    wget \
    stow \
    efibootmgr \
    limine \
    less \
    man-db \
    man-pages

step "Generating fstab"
genfstab -U /mnt > /mnt/etc/fstab

step "Configuring system"
install -m600 /dev/null /mnt/root-password
printf '%s' "$ROOT_PASSWORD" > /mnt/root-password

install -m600 /dev/null /mnt/user-password
printf '%s' "$USER_PASSWORD" > /mnt/user-password

chmod 600 /mnt/root-password
chmod 600 /mnt/user-password

install -m755 ./*.sh /mnt/

arch-chroot /mnt /chroot.sh \
    "$DISK" \
    "$ROOT_PART" \
    "$HOSTNAME" \
    "$USERNAME" \
    "$TIMEZONE" \
    "$LOCALE"

SUCCESS=true

info "Installation completed"

confirm "Reboot now?" && reboot