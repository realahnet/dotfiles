#!/usr/bin/env bash

set -e

echo "=== Installing Native Packages ==="
sudo pacman -S --needed - < pkglist.txt

echo "=== Symlinking Configurations ==="
mkdir -p ~/.config/fastfetch ~/.config/hypr ~/.config/swaync ~/.config/swayosd ~/.config/waybar ~/.config/wallpapers ~/.config/kitty

ln -sf ~/dotfiles/fastfetch/* ~/.config/fastfetch
ln -sf ~/dotfiles/hypr/* ~/.config/hypr/
ln -sf ~/dotfiles/swayosd/* ~/.config/swayosd
ln -sf ~/dotfiles/swaync/* ~/.config/swaync
ln -sf ~/dotfiles/waybar/* ~/.config/waybar/
ln -sf ~/dotfiles/wallpapers/* ~/.config/wallpapers/
ln -sf ~/dotfiles/kitty/* ~/.config/kitty

echo "=== Enabling System Dark Theme Preferences ==="
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

echo "=== Setting Wallpaper via awww ==="
awww img ~/.config/wallpapers/wallpaper.jpg

echo "Done! Restart Hyprland and waybar!"
