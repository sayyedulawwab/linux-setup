#!/usr/bin/env bash

sudo pacman -S docker

sudo usermod -aG docker "$USER"

sudo systemctl enable docker
sudo systemctl start docker