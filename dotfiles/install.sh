#!/usr/bin/env bash

if [ -z "$HOME" ]; then echo "Seems you're \$HOMEless :("; exit 1; fi

DOTFILES_ROOT=$HOME/.arch-config
DOTCONFIG=$HOME/.config
DOTFILES=$HOME/.arch-config/dotfiles

GITCLONE="git clone --depth=1"

cd "$HOME" || exit
rm -rf "$DOTFILES_ROOT"
mkdir "$DOTFILES_ROOT"
cd "$DOTFILES_ROOT" || exit

git clone git@github.com:OB3RG/arch-config.git $DOTFILES_ROOT

rm -rf \
  "$HOME/.gitconfig" \
  "$HOME/.zshrc" \
  "$DOTCONFIG/nvim" \
  "$DOTCONFIG/alacritty" \
  "$DOTCONFIG/i3status" \
  "$DOTCONFIG/rofi" \
  "$DOTCONFIG/sway" 

ln -s "$DOTFILES/gitconfig" "$HOME/.gitconfig"
ln -s "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
ln -s "$DOTFILES/config/nvim" "$DOTCONFIG/nvim"
ln -s "$DOTFILES/config/alacritty" "$DOTCONFIG/alacritty"
ln -s "$DOTFILES/config/i3status" "$DOTCONFIG/i3status"
ln -s "$DOTFILES/config/rofi" "$DOTCONFIG/rofi"
ln -s "$DOTFILES/config/sway" "$DOTCONFIG/sway"

cd "$HOME" || exit
rm -f "${HOME}/.zcompdump*"

echo "ENJOY! :)"
