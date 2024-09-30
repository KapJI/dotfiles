#!/bin/bash

function install_centos_packages() {
    setup_proxy
    local dnf_packages=(
        eza
        fd-find
        fzf
        htop
        gnupg
        neovim
        PackageKit-command-not-found
        pinentry-tty
        readline-devel
        ripgrep
        zoxide
    )
    sudo http_proxy="" https_proxy="" dnf install -y "${dnf_packages[@]}"
    if ! command_exists et; then
        sudo feature install et
    fi
    # Update rust
    env $(fwdproxy-config --format=sh curl) rustup update
}

function setup_proxy() {
    export CURL_CONFIG=$(fwdproxy-config curl)
    export http_proxy="http://fwdproxy:8080"
    export https_proxy="http://fwdproxy:8080"
}

function setup_centos() {
    echo "setup centos"
    sudo ln -sfn /usr/bin/pinentry-tty /usr/local/bin/pinentry-current
}
