#!/bin/bash

function add_eternal_terminal_repo() {
    if [ "$DEBIAN" = true ]; then
        local et_keyring="/usr/share/keyrings/et-archive-keyring.gpg"
        local et_sources_list="/etc/apt/sources.list.d/et.list"
        if [ ! -f "${et_keyring}" ]; then
            curl -sSL https://github.com/MisterTea/debian-et/raw/master/et.gpg \
            | gpg --dearmor | sudo tee "${et_keyring}" > /dev/null
        fi
        if [ ! -f "${et_sources_list}" ]; then
            local config_line="deb [arch=$(dpkg --print-architecture) "
            config_line+="signed-by=${et_keyring}] "
            config_line+="https://mistertea.github.io/debian-et/debian-source/ "
            config_line+="$(lsb_release --codename --short) main"
            echo "${config_line}" | sudo tee "${et_sources_list}" > /dev/null
        fi
    elif [ "$UBUNTU" = true ]; then
        sudo add-apt-repository ppa:jgmath2000/et -y -n
    fi
}

function add_eza_repo() {
    local eza_keyring="/etc/apt/keyrings/gierens_eza.gpg"
    local eza_sources_list="/etc/apt/sources.list.d/gierens_eza.list"
    if [ ! -f "${eza_keyring}" ]; then
        curl -sSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | gpg --dearmor | sudo tee "${eza_keyring}" > /dev/null
    fi
    if [ ! -f "${eza_sources_list}" ]; then
        echo "deb [signed-by=${eza_keyring}] http://deb.gierens.de stable main" \
        | sudo tee "${eza_sources_list}" > /dev/null
        sudo chmod 644 ${eza_keyring} ${eza_sources_list}
    fi
}

function install_nvm() {
    # Can be left by npm installed from apt.
    rm -f "$HOME/.npmrc"
    set +x
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    if ! command_exists nvm; then
        echo "Install nvm"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    fi
    set -x
}

function install_debian_packages() {
    # local apt_packages=(
    #     build-essential
    #     command-not-found
    #     eza
    #     fd-find
    #     fzf
    #     gnupg
    #     golang
    #     htop
    #     ncat
    #     neovim
    #     pinentry-tty
    #     python3
    #     python3-dev
    #     python3-pip
    #     python3-setuptools
    #     python3-venv
    #     ripgrep
    #     tmux
    #     zsh
    # )
    if [ "$RASPBERRY_PI" != true ]; then
        apt_packages+=(et)
        add_eternal_terminal_repo
    fi
    add_eza_repo
    sudo apt update
    sudo apt install -y "${apt_packages[@]}"
    sudo apt remove pipx
    # Install zoxide
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    install_nvm
}

function setup_debian() {
    # Create symlinks
    sudo ln -sfn $(command -v fdfind) /usr/local/bin/fd
    sudo ln -sfn /usr/bin/pinentry-tty /usr/local/bin/pinentry-current
}
