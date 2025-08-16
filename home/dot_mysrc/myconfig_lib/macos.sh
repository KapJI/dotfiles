#!/bin/bash

function install_macos_packages() {
    # Although not an installation but should come early
    # enable_sudo_touchid
    # if ! command_exists brew; then
    #     local brew_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    #     /bin/bash -c "$(curl -fsSL ${brew_url})"
    # fi
    # # Make sure CLI tools are installed.
    # while xcode-select --install 2>/dev/null; do
    #     echo "Waiting before Apple CLI tools are installed..."
    #     sleep 10
    # done
    # This output is very noisy
    # set +x
    # local brew_packages=(
    #     autoconf
    #     cmake
    #     dos2unix
    #     eza
    #     fd
    #     ffmpeg
    #     fpp
    #     fzf
    #     git
    #     gnupg
    #     go
    #     graphviz
    #     htop
    #     jq
    #     make
    #     ncdu
    #     neovim
    #     node
    #     python3
    #     ripgrep
    #     tree
    #     wget
    #     zoxide
    #     zsh
    #     mistertea/et/et
    # )
    # brew update
    # Find already installed packages
    # local upgrade_packages=($(brew ls --versions "${brew_packages[@]}" |
    # while read -r line; do
    #     package=$(echo $line | awk '{print $1;}')
    #     echo "$package"
    # done))
    # # Filter installed packages
    # local install_packages=()
    # local package
    # for package in "${brew_packages[@]}"; do
    #     local short_package="$(echo $package | awk -F '/' '{print $NF}')"
    #     if [[ ! " ${upgrade_packages[@]} " =~ " ${short_package} " ]]; then
    #         install_packages+=($package)
    #     fi
    # done
    # # Enable verbose mode back
    # set -x
    # for package in "${install_packages[@]}"; do
    #     sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/sbin
    #     HOMEBREW_NO_AUTO_UPDATE=1 brew install "${package}"
    # done
    # sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/sbin
    # if [ ${#upgrade_packages[@]} -gt 0 ]; then
    #     HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade "${upgrade_packages[@]}"
    # fi
    # # Install command-not-found
    # brew tap homebrew/command-not-found
    # install_subl_symlink
    install_copy_tool
    install_iterm_font
    # install_rustup
}

# function install_subl_symlink() {
#     if [ ! -L /usr/local/bin/subl ]; then
#         ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
#     fi
# }

function install_copy_tool() {
    if ! $HOME/bin/copy > /dev/null; then
        pushd "$HOME/.mysrc/copy"
        make clean
        make
        make install
        popd
    fi
}

# function install_rustup() {
#     # Install rustup
#     if ! command_exists rustup; then
#         curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
#     else
#         rustup update
#     fi
#     if ! command_exists cargo; then
#         source $HOME/.cargo/env
#     fi
# }

# function iterm_get() {
#   /usr/libexec/PlistBuddy -c "Print :$1" ~/Library/Preferences/com.googlecode.iterm2.plist
# }
# 
# function install_iterm_font() {
#     local font_base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
#     if [ "$TERM_PROGRAM" != "iTerm.app" ]; then
#         return 0
#     fi
#     [ -x "/usr/libexec/PlistBuddy" ]
#     [ -x "/usr/bin/plutil" ]
#     [ -x "/usr/bin/defaults" ]
#     [ -f "$HOME/Library/Preferences/com.googlecode.iterm2.plist" ]
#     [ -r "$HOME/Library/Preferences/com.googlecode.iterm2.plist" ]
#     [ -w "$HOME/Library/Preferences/com.googlecode.iterm2.plist" ]
#     local guid1="$(iterm_get '"Default Bookmark Guid"' 2>/dev/null)"
#     local guid2="$(iterm_get '"New Bookmarks":0:"Guid"' 2>/dev/null)"
#     local font="$(iterm_get '"New Bookmarks":0:"Normal Font"' 2>/dev/null)"
#     [ "$guid1" = "$guid2" ]
#     [[ $font != "MesloLGS-NF-Regular "* ]] || return 0
#     # Download fonts
#     command mkdir -p "$HOME/Library/Fonts"
#     local style
#     for style in Regular Bold Italic 'Bold Italic'; do
#         local file="MesloLGS NF ${style}.ttf"
#         curl -fsSL -o "$HOME/Library/Fonts/$file.tmp" "$font_base_url/${file// /%20}"
#         command mv -f "$HOME/Library/Fonts/$file"{.tmp,}
#     done
#     local settings=(
#         '"Normal Font"',string,'"MesloLGS-NF-Regular 14"'
#         '"Terminal Type"',string,'"xterm-256color"'
#         '"Horizontal Spacing"',real,1
#         '"Vertical Spacing"',real,1
#         '"Minimum Contrast"',real,0
#         '"Use Bold Font"',bool,1
#         '"Use Bright Bold"',bool,1
#         '"Use Italic Font"',bool,1
#         '"ASCII Anti Aliased"',bool,1
#         '"Non-ASCII Anti Aliased"',bool,1
#         '"Use Non-ASCII Font"',bool,0
#         '"Ambiguous Double Width"',bool,0
#         '"Draw Powerline Glyphs"',bool,1
#         '"Only The Default BG Color Uses Transparency"',bool,1
#         '"Show Mark Indicators"',bool,0
#     )
#     for row in "${settings[@]}"; do
#         local oldIFS="$IFS"
#         IFS=","
#         set -- $row
#         IFS="$oldIFS"
#         local key=$1 type=$2 value=$3
#         /usr/libexec/PlistBuddy -c "Set :\"New Bookmarks\":0:$key $value" \
#             ~/Library/Preferences/com.googlecode.iterm2.plist 2>/dev/null && continue
#         /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:$key $type $value" \
#             ~/Library/Preferences/com.googlecode.iterm2.plist
#     done
#     /usr/bin/defaults read com.googlecode.iterm2 > /dev/null
# }


# function setup_macos() {
#     disable_sonoma_cursor
# }

# function disable_sonoma_cursor() {
#     local preference_key="/Library/Preferences/FeatureFlags/Domain/UIKit.plist"
#     local dict_key="redesigned_text_cursor"

#     # Read the dictionary key
#     local dict_output=$(sudo defaults read "$preference_key" "$dict_key" 2>/dev/null)

#     # Check if the dictionary key output contains 'Enabled = 0;'
#     if [[ "$dict_output" =~ "Enabled = 0;" ]]; then
#         echo "Preference for redesigned text cursor is already set correctly."
#     else
#         echo "Setting preference for redesigned text cursor..."
#         # The value isn't set correctly or the key doesn't exist, set the value now
#         sudo defaults write "$preference_key" "$dict_key" -dict Enabled -bool NO
#         echo "Preference set successfully."
#     fi
# }

# function enable_sudo_touchid() {
#     # Enable sudo by TouchID
#     if ! grep -q "pam_tid.so" /etc/pam.d/sudo; then
#         sudo chmod +w /etc/pam.d/sudo
#         sudo /usr/bin/sed -i '' -e '2s/^/auth       sufficient     pam_tid.so\'$'\n/' \
#             /etc/pam.d/sudo
#         sudo chmod -w /etc/pam.d/sudo
#     fi
# }
