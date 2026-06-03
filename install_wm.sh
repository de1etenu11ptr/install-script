#!/bin/bash

USER=$1

function get_pkgbuild() {
	local current="$PWD"
	sudo -U

	cd "/home/$USER/projects/dwm/"
	sudo -U "$USER" git clone --depth=1 https://aur.archlinux.org/dwm.git dwm
	cd dwm	

	cd "$current"
}
