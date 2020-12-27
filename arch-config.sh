#!/bin/sh

#
# Archlinux auto desktop environment configurator. Run this after successful system install.
#

github=https://github.com/paultoliver

echo ":: Welcome to Archlinux user configurator"
echo ":: Installing dependencies"
sudo pacman -S --needed --noconfirm \
    base-devel \
    git \
    libxft \
    libxinerama \
    stow \
    ttf-jetbrains-mono \
    xorg-server \
    xorg-xinit \
    xorg-xrdb

echo
echo ":: Fetching repositories"
mkdir -p $HOME/repos
cd $HOME/repos
git clone $github/dmenu
git clone $github/dotfiles
git clone $github/dwm

echo
echo ":: Building dwm"
cd $HOME/repos/dwm
git remote add upstream https://git.suckless.org/dwm
git checkout arch-orbital
cp -v config.def.h config.h
make
sudo make install

echo
echo ":: Building dmenu"
cd $HOME/repos/dmenu
git remote add upstream https://git.suckless.org/dmenu
git checkout arch-orbital
cp -v config.def.h config.h
make
sudo make install

echo
echo ":: Stowing dotfiles"
cd $HOME/repos/dotfiles
stow -t $HOME xorg
