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
    feh \
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
mkdir -p $HOME/suckless
cd $HOME/suckless
git clone --depth 1 --single-branch --branch arch-orbital $github/dwm
git clone --depth 1 --single-branch --branch arch-orbital $github/dmenu
git clone --depth 1 --single-branch --branch arch-orbital $github/st
git clone --depth 1 --single-branch --branch master $github/dotfiles

echo
echo ":: Building dwm"
cd $HOME/suckless/dwm
git remote add upstream https://git.suckless.org/dwm
git checkout arch-orbital
cp -v config.def.h config.h
make
sudo make install

echo
echo ":: Building dmenu"
cd $HOME/suckless/dmenu
git remote add upstream https://git.suckless.org/dmenu
git checkout arch-orbital
cp -v config.def.h config.h
make
sudo make install

echo
echo ":: Building st"
cd $HOME/suckless/st
git remote add upstream https://git.suckless.org/st
git checkout arch-orbital
cp -v config.def.h config.h
make
sudo make install

echo
echo ":: Stowing dotfiles"
cd $HOME/suckless/dotfiles
stow -t $HOME xorg
