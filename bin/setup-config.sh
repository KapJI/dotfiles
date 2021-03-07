#!/bin/bash

set -e

function config_init() {
    set -x
    # Request sudo in the beginning
    sudo true
    install_packages
    setup_machine
    # Set current user shell to zsh
    set_zsh_shell
    config_update
}

function config_update() {
    set -x
    git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME pull
    antigen update
    nvim +PlugUpgrade +PlugUpdate +qall
    # Nothing will run after this
    exec zsh
}

function set_zsh_shell() {
    if [ "$MACOS" = true ]; then
        zsh_path="/bin/zsh"
    else
        zsh_path="$(which zsh)"
    fi
    if [ "$SHELL" != "$zsh_path" ]; then
        chsh -s "$zsh_path"
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
    else
        install_centos_packages
    fi
    # Install antigen
    curl -L git.io/antigen > antigen.zsh
    # Install vim-plug
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
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
}

function install_macos_packages() {
    if ! command_exists brew; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew_packages=(
        broot
        cmake
        dos2unix
        fasd
        fd
        fpp
        fzf
        git
        go
        gpg2
        graphviz
        htop
        jq
        lsd
        ncdu
        neovim
        node
        pinentry-mac
        pipx
        ripgrep
        the_silver_searcher
        thefuck
        tree
        wget
        zsh
    )
    brew update
    # Find already installed packages
    upgrade_packages=($(brew ls --versions "${brew_packages[@]}" |
    while read -r line; do
        package=$(echo $line | awk '{print $1;}')
        echo "$package"
    done))
    # Filter installed packages
    install_packages=()
    for package in "${brew_packages[@]}"; do
        if [[ ! " ${upgrade_packages[@]} " =~ " ${package} " ]]; then
            install_packages+=($package)
        fi
    done
    sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/sbin
    if [ ${#install_packages[@]} -gt 0 ]; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew install "${install_packages[@]}"
    fi
    if [ ${#upgrade_packages[@]} -gt 0 ]; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade "${upgrade_packages[@]}"
    fi
    sudo ln -s /usr/local/bin/pinentry-mac /usr/local/bin/pinentry-current
}

function install_debian_packages() {
    apt_packages=(
        fasd
        fd-find
        fzf
        gnupg
        golang
        neovim
        pinentry-tty
        python3
        python3-dev
        python3-pip
        python3-setuptools
        ripgrep
        tmux
        zsh
        htop
    )
    # Current Ubuntu distro is not available in this PPA
    if [ "$ID" = "ubuntu" ]; then
        sudo add-apt-repository -y "deb http://ppa.launchpad.net/aacebedo/fasd/ubuntu/ eoan main"
    else
        sudo add-apt-repository -y ppa:aacebedo/fasd
    fi
    sudo apt update
    sudo apt install -y "${apt_packages[@]}"
    sudo ln -s $(which fdfind) /usr/local/bin/fd
    sudo ln -s /usr/bin/pinentry-tty /usr/local/bin/pinentry-current
    python3 -m pip install --user pipx
    pipx install thefuck
    # Cargo needs to be installed before this
    cargo install lsd
    cargo install broot
}

function install_centos_packages() {
    echo "install centos packages"
}

function setup_machine() {
    if [ "$MACOS" = true ]; then
        setup_macos
    fi
}

function setup_macos() {
    # Enable sudo by TouchID
    if ! grep -q "pam_tid.so" /etc/pam.d/sudo; then
        sudo chmod +w /etc/pam.d/sudo
        sudo /usr/bin/sed -i '' -e '2s/^/auth       sufficient     pam_tid.so\'$'\n/' /etc/pam.d/sudo
        sudo chmod -w /etc/pam.d/sudo
    fi
    # Protect secret directories
    chmod -R 700 ~/.ssh
    chmod -R 700 ~/.gnupg
}

function command_exists() {
    command -v "$1" &> /dev/null
}

function error() {
    echo "ERROR: $1"
    exit 1
}

function usage() {
    set +x
    echo "Usage: $0 [arguments]"
    echo "Arguments:"
    echo "  init:           initial configuration setup on this machine"
    echo "  update:         update configuration on this machine from upsteam"
    echo "  upgrade:        full upgrade of configuration and installed packages"
    echo "  -h or --help:   show this message and exit"
}

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOS=true
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            centos)
                CENTOS=true
                ;;
            debian|ubuntu)
                DEBIAN_BASED=true
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

# Parse arguments
if [[ $# -ne 1 ]]; then
    usage
fi

COMMAND="$1"
case $COMMAND in
    init|upgrade)
        config_init
        ;;
    update)
        config_update
        ;;
    -h|--help)
        usage
        ;;
esac
