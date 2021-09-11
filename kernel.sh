#!/bin/sh
#
# Copyright (C) 2021 Rick <riyyi3@gmail.com>
#
# SPDX-License-Identifier: GPL-2.0-only
#
# Build the Linux kernel
# Depends: asp, base-devel

# Setup
# --------------------------------------

b="$(tput bold)"
u="$(tput smul)"
blue="$(tput setf 1)"
red="$(tput setf 4)"
n="$(tput sgr0)"

if [ "$(dirname "$0")" != "." ]; then
	echo "${b}${red}Error:${n} please run this script from the directory it resides." >&2
	exit 1
fi

# Main functionality
# --------------------------------------

cdSafe()
{
	if ! cd "$1" 2> /dev/null; then
		echo "${b}${red}Error:${n} no such file or directory: $1" >&2
		exit 1
	fi
}

checkDependencies()
{
	dependencies="
		asp
		base-devel
	"

	for dependency in $dependencies; do
		if ! pacman -Qs "$dependency" > /dev/null; then
			echo "${b}${red}Error:${n} required dependency '$dependency' is missing." >&2
			exit 1
		fi
	done
}

build()
{
	cdSafe build

	rm -rf "./linux"
	asp update linux
	asp export linux
	[ -f linux/config ] && mv linux/config .
	[ -f linux/PKGBUILD ] && mv linux/PKGBUILD .
	rm -rf "./linux"

	patch --forward --strip=1 config < ../patch/config.patch
	patch --forward --strip=1 PKGBUILD < ../patch/pkgbuild.patch

	ln -s ../patch/i2c-hid-disable-incomplete-reports.patch .

	updpkgsums

	printf "\n%s=>> Edit linux/%sPKGBUILD%s? [y/N]: " "${u}${blue}" "${n}${b}${u}" "${n}"
	read -r edit
	if [ "$edit" = "y" ] || [ "$edit" = "Y" ]; then
		$EDITOR PKGBUILD
	fi

	time makepkg -s
}

# Execute
# --------------------------------------

checkDependencies
build
