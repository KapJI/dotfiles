#!/bin/bash

function setup_main() {
    set -x
    # Request sudo in the beginning
    sudo true

    detect_os
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

function complete_update() {
    nvim +PlugUpgrade +PlugUpdate +qall
    # Nothing will run after this
    exec zsh
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
    curl -L git.io/antigen > ~/antigen.zsh
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
    install_python_packages
    install_npm_packages
}

function install_python_packages() {
    local pipx_packages
    pipx_packages=(
        poetry
        pre-commit
        thefuck
    )
    for package in "${pipx_packages[@]}"; do
        if ! command_exists "$package"; then
            pipx install "$package"
        else
            pipx upgrade "$package"
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

function install_macos_packages() {
    local brew_packages upgrade_packages install_packages short_package
    if ! command_exists brew; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
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
    sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/sbin
    if [ ${#install_packages[@]} -gt 0 ]; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew install "${install_packages[@]}"
    fi
    if [ ${#upgrade_packages[@]} -gt 0 ]; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade "${upgrade_packages[@]}"
    fi
}

function add_eternal_terminal_repo() {
    if [ "$DEBIAN" = true ]; then
        local et_keyring et_sources_list
        et_keyring="/usr/share/keyrings/et-archive-keyring.gpg"
        et_sources_list="/etc/apt/sources.list.d/et.list"
        if [ ! -f "${et_keyring}" ]; then
            curl -sSL https://github.com/MisterTea/debian-et/raw/master/et.gpg \
            | gpg --dearmor | sudo tee "${et_keyring}" > /dev/null
        fi
        if [ ! -f "${et_sources_list}" ]; then
            echo "deb [arch=$(dpkg --print-architecture) signed-by=${et_keyring}] https://github.com/MisterTea/debian-et/raw/master/debian-source/ buster main" \
            | sudo tee "${et_sources_list}" > /dev/null
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

function install_centos_packages() {
    echo "install centos packages"
}

function setup_machine() {
    if [ "$MACOS" = true ]; then
        setup_macos
    elif [ "$DEBIAN_BASED" = true ]; then
        setup_debian
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
    # Create symlink to pinentry-mac
    sudo ln -sfn /usr/local/bin/pinentry-mac /usr/local/bin/pinentry-current
}

function setup_debian() {
    # Create symlinks
    sudo ln -sfn $(which fdfind) /usr/local/bin/fd
    sudo ln -sfn /usr/bin/pinentry-tty /usr/local/bin/pinentry-current
}

function command_exists() {
    command -v "$1" &> /dev/null
}
