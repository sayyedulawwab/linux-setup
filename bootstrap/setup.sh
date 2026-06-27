#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Updating system"
sudo pacman -Syu

echo "==> Installing packages"

for file in "$REPO_DIR"/bootstrap/packages/*.txt
do
    sudo pacman -S --needed --noconfirm $(grep -v '^#' "$file")
done

echo "==> Installing Brave"
curl -fsS https://dl.brave.com/install.sh | sh

echo "==> Installing paru"

if ! command -v paru >/dev/null 2>&1; then
    TMPDIR=$(mktemp -d)

    git clone https://aur.archlinux.org/paru.git "$TMPDIR/paru"

    (
        cd "$TMPDIR/paru"
        makepkg -si --noconfirm
    )

    rm -rf "$TMPDIR"
fi

echo "==> Installing AUR packages"
paru -S --needed --noconfirm hyprpaper-git

echo "==> Running NVIDIA setup"
bash "$REPO_DIR/bootstrap/nvidia.sh"

echo "==> Running Docker setup"
bash "$REPO_DIR/bootstrap/docker.sh"

echo "==> Applying dotfiles"

sudo pacman -S --needed --noconfirm stow

cd "$REPO_DIR/dotfiles"

stow shell
stow vim
stow alacritty
stow hypr
stow waybar
stow walls

echo "==> Setup complete"