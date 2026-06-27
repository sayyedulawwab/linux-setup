#!/usr/bin/env bash

set -euo pipefail

read -rp "Git name: " GIT_NAME
read -rp "Git email: " GIT_EMAIL

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

git config --global init.defaultBranch main

echo "Git configured"