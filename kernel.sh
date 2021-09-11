#!/bin/sh
#
# Copyright (C) 2021 Rick <riyyi3@gmail.com>
#
# SPDX-License-Identifier: GPL-2.0-only
#
# Build the Linux kernel
# Depends: asp, base-devel, coreutils

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

help()
{
	cat << EOF
${b}NAME${n}
	kernel.sh - build the Linux kernel

${b}SYNOPSIS${n}
	${u}kernel.sh${n} [${u}OPTION${n}] ${u}COMMAND${n}

${b}OPTIONS${n}
	${b}-h${n}, ${b}--help${n}	Display usage message and exit.

${b}COMMANDS${n}
	${b}build${n}
		Build the kernel, this is the default.

	${b}install${n}
		Install the kernel.
EOF
}

# Main functionality
# --------------------------------------

cdSafe()
{
	if ! cd "$1" 2> /dev/null; then
		echo "${b}${red}Error:${n} no such file or directory: $1" >&2
		exit 1
	fi
}

fileExist()
{
	if [ ! -f "$1" ] ; then
		echo "${b}${red}Error:${n} no such file or directory: $1" >&2
		exit 1
	fi
}

checkDependencies()
{
	dependencies="
		asp
		base-devel
		coreutils
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
	fileExist linux/config && mv linux/config .
	fileExist linux/PKGBUILD && mv linux/PKGBUILD .
	rm -rf "./linux"

	patch --forward --strip=1 config < ../patch/config.patch
	patch --forward --strip=1 PKGBUILD < ../patch/pkgbuild.patch

	ln -s ../patch/i2c-hid-disable-incomplete-reports.patch . 2> /dev/null

	updpkgsums

	printf "\n%s=>> Edit linux/%sPKGBUILD%s? [y/N]: " "${u}${blue}" "${n}${b}${u}" "${n}"
	read -r edit
	if [ "$edit" = "y" ] || [ "$edit" = "Y" ]; then
		$EDITOR PKGBUILD
	fi

	time makepkg -s
}

install()
{
	cdSafe build

	packages="$(find . -name "*.tar.zst" -type f)"

	found="$(echo "$packages" | wc -l)"
	if [ "$found" -ne 2 ]; then
		echo "${b}${red}Error:${n} kernel was not build yet." >&2
		exit 1
	fi

	if ! sudo -v; then
		echo "${b}${red}Error:${n} you cannot perform this operation uness you are root." >&2
		exit 1
	fi

	echo "$packages" | xargs --open-tty sudo pacman -U --needed
}

# Execute
# --------------------------------------

checkDependencies

script="$(basename "$0")"
case "$1" in
	-h | --help)
		help
		;;
	build | "")
		build
		;;
	install)
		install
		;;
	*)
		echo "$script: invalid option '$1'" >&2
		echo "Try '$script -h' for more information." >&2
		exit 1
		;;
esac
