#!/bin/bash

function add_eternal_terminal_repo() {
    if [ "$DEBIAN" = true ]; then
        local et_keyring et_sources_list config_line
        et_keyring="/usr/share/keyrings/et-archive-keyring.gpg"
        et_sources_list="/etc/apt/sources.list.d/et.list"
        if [ ! -f "${et_keyring}" ]; then
            curl -sSL https://github.com/MisterTea/debian-et/raw/master/et.gpg \
            | gpg --dearmor | sudo tee "${et_keyring}" > /dev/null
        fi
        if [ ! -f "${et_sources_list}" ]; then
            config_line="deb [arch=$(dpkg --print-architecture) "
            config_line+="signed-by=${et_keyring}] "
            config_line+="https://github.com/MisterTea/debian-et/raw/master/debian-source/ "
            config_line+="buster main"
            echo "${config_line}" | sudo tee "${et_sources_list}" > /dev/null
        fi
    elif [ "$UBUNTU" = true ]; then
        sudo add-apt-repository ppa:jgmath2000/et -y -n
    fi
}

function install_debian_packages() {
    local apt_packages
    apt_packages=(
        et
        fasd
        fd-find
        fzf
        gnupg
        golang
        htop
        ncat
        neovim
        npm
        pinentry-tty
        python3
        python3-dev
        python3-pip
        python3-setuptools
        python3-venv
        ripgrep
        tmux
        zsh
    )
    add_eternal_terminal_repo
    sudo apt update
    sudo apt install -y "${apt_packages[@]}"
    python3 -m pip install --user pipx
    # Cargo needs to be installed before this
    cargo install lsd
    cargo install broot
}

function setup_debian() {
    # Create symlinks
    sudo ln -sfn $(which fdfind) /usr/local/bin/fd
    sudo ln -sfn /usr/bin/pinentry-tty /usr/local/bin/pinentry-current
}
