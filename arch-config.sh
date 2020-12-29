#!/bin/sh

#
# Archlinux auto desktop environment configurator. Run this after successful system install.
#

github=https://github.com/paultoliver

echo ":: Welcome to Archlinux user configurator"
echo ":: Installing dependencies"
sudo pacman -S --needed --noconfirm \
    adwaita-icon-theme \
    base-devel \
    git \
    libxcursor \
    libxft \
    libxinerama \
    stow \
    ttf-jetbrains-mono \
    xorg-server \
    xorg-xinit \
    xorg-xrdb

echo
echo ":: Fetching suckless repositories"
mkdir -p $HOME/repos
cd $HOME/repos
git clone $github/dmenu
git clone $github/dotfiles
git clone $github/dwm
git clone $github/st

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
echo ":: Building st"
cd $HOME/repos/st
git remote add upstream https://git.suckless.org/st
git checkout arch-orbital
cp -v config.def.h config.h
make
sudo make install

echo
echo ":: Stowing dotfiles"
cd $HOME/repos/dotfiles
stow -t $HOME xorg
