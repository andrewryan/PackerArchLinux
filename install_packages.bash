#!/usr/bin/env bash

printf "=====> %s\n" "Installing additional packages"


printf "2\ny\n"|pacman -S virtualbox-guest-utils-nox
pacman -S --noconfirm vim
