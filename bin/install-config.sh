#!/bin/bash

set -ex
shopt -s expand_aliases

alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
git clone --bare https://github.com/KapJI/dotfiles.git ~/.dotfiles
dotfiles config --local status.showUntrackedFiles no
dotfiles checkout

~/bin/setup-config.sh init