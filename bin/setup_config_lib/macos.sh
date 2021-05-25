#!/bin/bash

function install_macos_packages() {
    local brew_packages upgrade_packages install_packages short_package
    if ! command_exists brew; then
        brew_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
        /bin/bash -c "$(curl -fsSL ${brew_url})"
    fi
    # Make sure CLI tools are installed.
    while xcode-select --install 2>/dev/null; do
        echo "Waiting before Apple CLI tools are installed..."
        sleep 10
    done
    # This output is very noisy
    set +x
    brew_packages=(
        ant
        broot
        cmake
        dos2unix
        fasd
        fd
        fpp
        fzf
        git
        gnupg
        go
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
        tree
        wget
        zsh
        mistertea/et/et
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
        short_package="$(echo $package | awk -F '/' '{print $NF}')"
        if [[ ! " ${upgrade_packages[@]} " =~ " ${short_package} " ]]; then
            install_packages+=($package)
        fi
    done
    # Enable verbose mode back
    set -x
    for package in "${install_packages[@]}"; do
        sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/sbin
        HOMEBREW_NO_AUTO_UPDATE=1 brew install "${package}"
    done
    sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/sbin
    if [ ${#upgrade_packages[@]} -gt 0 ]; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade "${upgrade_packages[@]}"
    fi
}

function setup_macos() {
    # Enable sudo by TouchID
    if ! grep -q "pam_tid.so" /etc/pam.d/sudo; then
        sudo chmod +w /etc/pam.d/sudo
        sudo /usr/bin/sed -i '' -e '2s/^/auth       sufficient     pam_tid.so\'$'\n/' \
            /etc/pam.d/sudo
        sudo chmod -w /etc/pam.d/sudo
    fi
    # Protect secret directories
    chmod -R 700 ~/.ssh
    chmod -R 700 ~/.gnupg
    # Create symlink to pinentry-mac
    sudo ln -sfn /usr/local/bin/pinentry-mac /usr/local/bin/pinentry-current
}
