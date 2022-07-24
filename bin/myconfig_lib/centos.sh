#!/bin/bash

function install_centos_packages() {
    local dnf_packages
    dnf_packages=(
        htop
        ripgrep
    )
    sudo dnf install -y ripgrep
    if ! command_exists et; then
        sudo feature install et
    fi
    # install nvim
    if ! command_exists nvim; then
        sudo curl $(fwdproxy-config curl) -o /usr/local/bin/nvim -LO https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage
        sudo chmod +x /usr/local/bin/nvim
    fi
}

function setup_centos() {
    echo "setup centos"
}
