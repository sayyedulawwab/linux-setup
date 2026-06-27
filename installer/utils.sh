#!/usr/bin/env bash

set -eEuo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

LOG_FILE="/tmp/arch-install.log"

exec > >(tee -a "$LOG_FILE") 2>&1

info() {
    echo -e "${GREEN}${BOLD}==>${NC} $1"
}

warn() {
    echo -e "${YELLOW}${BOLD}WARNING:${NC} $1"
}

error() {
    echo -e "${RED}${BOLD}ERROR:${NC} $1"
    exit 1
}

confirm() {
    read -rp "$1 [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}