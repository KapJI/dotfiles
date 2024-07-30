#!/bin/bash

function install_centos_packages() {
    local dnf_packages=(
        fd-find
        fzf
        htop
        gnupg
        neovim
        pinentry-tty
        pipx
        readline-devel
        ripgrep
    )
    sudo dnf install -y "${dnf_packages[@]}"
    if ! command_exists et; then
        sudo feature install et
    fi
}

function setup_centos() {
    echo "setup centos"
}
