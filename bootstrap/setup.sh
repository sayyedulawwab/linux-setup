#!/usr/bin/env bash
# setup.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Updating system"
sudo pacman -Syu --noconfirm

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

echo "==> Installing pacman packages"

for file in "$REPO_DIR"/bootstrap/packages/*.txt
do
    [[ "$(basename "$file")" == "aur.txt" ]] && continue

    mapfile -t packages < <(
        grep -Ev '^\s*$|^\s*#' "$file"
    )

    if (( ${#packages[@]} > 0 )); then
        sudo pacman -S --needed --noconfirm "${packages[@]}"
    fi
done

echo "==> Installing AUR packages"

mapfile -t aur_packages < <(
    grep -Ev '^\s*$|^\s*#' \
    "$REPO_DIR/bootstrap/packages/aur.txt"
)

paru -S --needed --noconfirm "${aur_packages[@]}"

echo "==> Running NVIDIA setup"
bash "$REPO_DIR/bootstrap/nvidia.sh"

echo "==> Running Docker setup"
bash "$REPO_DIR/bootstrap/docker.sh"

echo "==> Running Bluetooth setup"
bash "$REPO_DIR/bootstrap/bluetooth.sh"

echo "==> Applying dotfiles"

cd "$REPO_DIR/dotfiles"

for dir in */
do
    stow -R "${dir%/}"
done

echo "==> Enabling services"

systemctl --user daemon-reload

sudo systemctl enable --now docker
sudo systemctl enable --now fstrim.timer

echo
echo "======================================"
echo "Setup complete"
echo "Reboot recommended"
echo "======================================"