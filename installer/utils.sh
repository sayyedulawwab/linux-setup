#!/usr/bin/env bash
# utils.sh
set -eEuo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'
BLUE='\033[0;34m'

export TERM=xterm-256color

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

STEP=1

step() {
    echo
    echo -e "${BLUE}${BOLD}[STEP $STEP]${NC} $1"
    STEP=$((STEP + 1))
}