#!/bin/bash

sudo pacman -Sy

sudo pacman -S --noconfirm zsh zsh-autosuggestions zsh-syntax-highlighting fzf gnome-keyring seahorse obsidian syncthing ripgrep ttf-liberation go

sleep 5
echo "Reboot"
