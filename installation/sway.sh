#!/bin/bash

sudo timedatectl set-ntp true
sudo hwclock --systohc

sudo reflector -c Sweden -a 12 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Sy

sudo pacman -S --noconfirm gdm sway swaylock swayidle swaybg foot wmenu arc-gtk-theme arc-icon-theme firefox gnu-free-fonts ttf-ubuntu-font-family rofi-wayland otf-opendyslexic-nerd i3status

sudo systemctl enable gdm
sleep 5
echo "Reboot"

