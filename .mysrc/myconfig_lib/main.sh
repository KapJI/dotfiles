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
    if [ "$MACOS" = true ]; then
        install_macos_packages
    elif [ "$DEBIAN_BASED" = true ]; then
        install_debian_packages
    elif [ "$CENTOS" = true ]; then
        install_centos_packages
    fi
    # Install vim-plug
    curl $CURL_CONFIG -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    install_python_packages
    install_npm_packages
}

function install_python_packages() {
    if ! command_exists uv; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    local packages=(
        mypy
        poetry
        pre-commit
        pygments
    )
    local package
    for package in "${packages[@]}"; do
        uv tool install --upgrade "$package"
    done
    uv tool install --upgrade thefuck --python python3.11
}

function install_npm_packages() {
    # Don't install npm on centos
    if [ "$CENTOS" = true ]; then
        return
    fi
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
    # Update nvim plugins
    nvim +PlugUpgrade +PlugUpdate +qall
    # Remove legacy files
    if [ -f "$HOME/antigen.zsh" ]; then
        rm "$HOME/antigen.zsh"
    fi
    if [ -f "$HOME/.zcompdump" ]; then
        rm "$HOME/.zcompdump"
    fi
    if [ -f "$HOME/.zshrc.zwc" ]; then
        rm -f "$HOME/.zshrc.zwc"
    fi
    if [ -f "$HOME/.zsh_history" ] && [ ! -f "$HOME/.config/zsh/.zsh_history" ]; then
        mv "$HOME/.zsh_history" "$HOME/.config/zsh/.zsh_history"
    fi
    # Update antidote plugins
    if [ -f "$HOME/.config/zsh/antidote/antidote.zsh" ]; then
        zsh -c 'source ~/.config/zsh/antidote/antidote.zsh; antidote update'
    fi
    # Update allowed_signers
    if [ ! -f "$HOME/.ssh/allowed_signers" ]; then
      touch "$HOME/.ssh/allowed_signers"
    fi
    signingkey=$(git config --global user.signingkey)
    if [ -n "$signingkey" ] && ! grep -q "$signingkey" "$HOME/.ssh/allowed_signers"; then
      echo "ruslan@sayfutdinov.com $signingkey" >> "$HOME/.ssh/allowed_signers"
    fi
    # Protect secret directories
    if [ -d "$HOME/.ssh" ]; then
      chmod 700 "$HOME/.ssh"
      find "$HOME/.ssh" -type f -exec chmod 600 {} \;
    fi
    if [ -d "$HOME/.gnupg" ]; then
      chmod 700 "$HOME/.gnupg"
      find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
    fi
    migrate_from_fasd
}

function migrate_from_fasd() {
    if [ -f "$HOME/.cache/fasd" ]; then
        zoxide import --from=z $HOME/.cache/fasd --merge
        rm $HOME/.cache/fasd
    fi
    if [ -f "$HOME/.fasd" ]; then
        zoxide import --from=z $HOME/.fasd --merge
        rm $HOME/.fasd
    fi
}

function set_zsh_shell() {
    if [ "$CENTOS" = true ]; then
        echo "Shell should be changed in 'i unix/shell'"
        return
    fi
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
    if command_exists tmux; then
        tmux source-file $HOME/.tmux.conf
    fi
    echo "Completed successfully!"
    # Nothing will run after this
    exec zsh
}

function command_exists() {
    command -v "$1" &> /dev/null
}
