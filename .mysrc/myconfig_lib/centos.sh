#!/bin/bash

function install_centos_packages() {
    local dnf_packages=(
        fd
        htop
        readline-devel
        ripgrep
    )
    sudo dnf install -y "${dnf_packages[@]}"
    if ! command_exists et; then
        sudo feature install et
    fi
    # install nvim
    if ! command_exists nvim; then
        sudo feature install neovim
    fi
}

function setup_centos() {
    echo "setup centos"
}
