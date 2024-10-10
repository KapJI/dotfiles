#!/bin/bash

function install_centos_packages() {
    local dnf_packages=(
        bat
        btop
        cmake
        eza
        fd-find
        fzf
        hexyl
        hyperfine
        git-delta
        gnupg
        neovim
        PackageKit-command-not-found
        pinentry-tty
        readline-devel
        ripgrep
        zoxide
        zsh
    )
    sudo dnf install -y "${dnf_packages[@]}"
    if ! command_exists et; then
        sudo feature install et
    fi
    # TODO: Install age
    # TODO: Install uv
    # TODO: Install ov
    # Update rust
    env $(fwdproxy-config --format=sh curl) rustup update
    setup_proxy
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
