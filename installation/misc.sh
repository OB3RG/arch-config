#!/bin/bash

sudo pacman -Sy

sudo pacman -S --noconfirm zsh zsh-autosuggestions zsh-syntax-highlighting fzf gnome-keyring seahorse

sleep 5
echo "Reboot"
