#!/bin/bash

function setup_main() {
    set -x
    # Request sudo in the beginning
    sudo true

    detect_os
    import_scripts
    install_packages
    setup_machine
    # Set current user shell to zsh
    set_zsh_shell
    complete_update
}

function detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        MACOS=true
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            case $ID in
                centos)
                    CENTOS=true
                    ;;
                debian)
                    DEBIAN_BASED=true
                    DEBIAN=true
                    ;;
                ubuntu)
                    DEBIAN_BASED=true
                    UBUNTU=true
                    ;;
                *)
                    error "running on unknown Linux distro: ${ID}!"
                    ;;
            esac
        else
            error "can't detect Linux distro!"
        fi
    else
        error "running on unknown OS: ${OSTYPE}!"
    fi
}

function import_scripts() {
    local current_dir
    current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    if [ "$MACOS" = true ]; then
        source "${current_dir}/macos.sh"
    elif [ "$DEBIAN_BASED" = true ]; then
        source "${current_dir}/debian_based.sh"
    elif [ "$CENTOS" = true ]; then
        source "${current_dir}/centos.sh"
    fi
}

function install_packages() {
    # Install rustup
    if ! command_exists rustup; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    else
        rustup update
    fi
    if ! command_exists cargo; then
        source $HOME/.cargo/env
    fi
    if [ "$MACOS" = true ]; then
        install_macos_packages
    elif [ "$DEBIAN_BASED" = true ]; then
        install_debian_packages
    elif [ "$CENTOS" = true ]; then
        install_centos_packages
    fi
    # Install antigen
    curl -L git.io/antigen > ~/antigen.zsh
    # Install vim-plug
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    # Install chroma. Go should be installed by now
    if ! command_exists chroma; then
        go get -u github.com/alecthomas/chroma/cmd/chroma
    fi
    # Configure broot
    if [ ! -f "${HOME}/.config/broot/launcher/bash/br" ]; then
        mkdir -p ${HOME}/.config/broot/launcher/bash
        broot --print-shell-function zsh > ${HOME}/.config/broot/launcher/bash/br
        broot --set-install-state installed
    fi
    install_python_packages
    install_npm_packages
}

function install_python_packages() {
    local pipx_packages pipx_path
    pipx_packages=(
        poetry
        pre-commit
        thefuck
    )
    if command_exists pipx; then
        pipx_path="pipx"
    else
        if [ "$MACOS" = true ]; then
            pipx_path="~/Library/Python/3.9/bin/pipx"
        else
            pipx_path="~/.local/bin/pipx"
        fi
    fi
    for package in "${pipx_packages[@]}"; do
        if ! command_exists "$package"; then
            ${pipx_path} install "$package"
        else
            ${pipx_path} upgrade "$package"
        fi
    done
}

function install_npm_packages() {
    local npm_prefix
    npm_prefix="$HOME/.npm"
    npm config set prefix "${npm_prefix}"
    if [ ! -d "${npm_prefix}/lib" ]; then
        mkdir -p "${npm_prefix}/lib"
    fi
    if ! npm list --global "git-branch-select"; then
        npm install --global "git-branch-select"
    fi
}

function setup_machine() {
    if [ "$MACOS" = true ]; then
        setup_macos
    elif [ "$DEBIAN_BASED" = true ]; then
        setup_debian
    elif [ "$CENTOS" = true ]; then
        setup_centos
    fi
}

function set_zsh_shell() {
    local zsh_path current_shell
    zsh_path="$(which zsh)"
    if [ "$MACOS" = true ]; then
        current_shell="$(dscl . -read /Users/$USER UserShell | awk  '{print $2}')"
        if [ "$current_shell" != "$zsh_path" ]; then
            sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh
        fi
    else
        current_shell="$(readlink -f $SHELL)"
        if [ "$current_shell" != "$zsh_path" ]; then
            chsh -s "$zsh_path"
        fi
    fi
}

function complete_update() {
    nvim +PlugUpgrade +PlugUpdate +qall
    if command_exists tmux; then
        tmux source-file ~/.tmux.conf
    fi
    # Nothing will run after this
    exec zsh
}

function command_exists() {
    command -v "$1" &> /dev/null
}
