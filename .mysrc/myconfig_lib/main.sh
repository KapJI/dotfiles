#!/bin/bash

function setup_main() {
    set -x
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
                    if grep Raspberry /proc/cpuinfo; then
                        RASPBERRY_PI=true
                    fi
                    ;;
                ubuntu|pop)
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
    local current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
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
    curl -L git.io/antigen > $HOME/antigen.zsh
    # Install vim-plug
    curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    # Install chroma. Go should be installed by now
    if ! command_exists chroma; then
        go env -w GO111MODULE=off
        go get -u github.com/alecthomas/chroma/cmd/chroma
    fi
    # Configure broot
    if [ ! -f "$HOME/.config/broot/launcher/bash/br" ]; then
        mkdir -p $HOME/.config/broot/launcher/bash
        broot --print-shell-function zsh > $HOME/.config/broot/launcher/bash/br
        broot --set-install-state installed
    fi
    install_python_packages
    install_npm_packages
}


function cleanup_pipx() {
    # When Python is upgraded pipx may start to fail:
    # https://github.com/pypa/pipx/issues/278
    rm -rf "$HOME/.local/pipx/shared"
}

function install_python_packages() {
    local pipx_packages=(
        poetry
        pre-commit
        thefuck
    )
    local pipx_path
    if command_exists pipx; then
        pipx_path="pipx"
    else
        if [ "$MACOS" = true ]; then
            pipx_path="$HOME/Library/Python/3.9/bin/pipx"
        else
            pipx_path="$HOME/.local/bin/pipx"
        fi
        if [ ! -f "$pipx_path" ]; then
            error "Can't find pipx"
        fi
    fi
    local package
    for package in "${pipx_packages[@]}"; do
        if ! command_exists "$package"; then
            ${pipx_path} install "$package" || (cleanup_pipx && ${pipx_path} reinstall-all && ${pipx_path} install "$package")
        else
            ${pipx_path} upgrade "$package" || (cleanup_pipx && ${pipx_path} reinstall-all)
        fi

    done
}

function install_npm_packages() {
    # Upgrade npm if it's failing
    if [ "$DEBIAN_BASED" = true ]; then
        if ! npm -v; then
            set +x
            echo "nvm install stable"
            nvm install stable
            set -x
        fi
    fi
    if [ "$MACOS" = true ]; then
        local npm_prefix="$HOME/.npm"
        npm config set prefix "${npm_prefix}"
        if [ ! -d "${npm_prefix}/lib" ]; then
            mkdir -p "${npm_prefix}/lib"
        fi
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
    local zsh_path="$(command -v zsh)"
    local current_shell
    if [ "$MACOS" = true ]; then
        current_shell="$(dscl . -read /Users/$USER UserShell | awk  '{print $2}')"
        if [ "$current_shell" != "$zsh_path" ]; then
            sudo dscl . -create "/Users/$USER" UserShell "$zsh_path"
        fi
    else
        current_shell="$(readlink -f $SHELL)"
        new_shell="$(readlink -f $zsh_path)"
        if [ "$current_shell" != "$new_shell" ]; then
            chsh -s "$zsh_path"
        fi
    fi
}

function complete_update() {
    nvim +PlugUpgrade +PlugUpdate +qall
    if command_exists tmux; then
        tmux source-file $HOME/.tmux.conf
    fi
    # Nothing will run after this
    exec zsh
}

function command_exists() {
    command -v "$1" &> /dev/null
}
