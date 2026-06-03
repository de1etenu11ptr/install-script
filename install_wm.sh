#!/bin/bash

USER=$1

function get_pkgbuild() {
	pacman -S xorg-server xorg-xinit xorg-xrandr xorg-xsetroot firefox-developer-edition kitty
	local current="$PWD"
	sudo -U

	cd "/home/$USER/projects/dwm/"
	sudo -U "$USER" git clone --depth=1 https://aur.archlinux.org/dwm.git dwm
	cd dwm	

	cd "$current"
}
