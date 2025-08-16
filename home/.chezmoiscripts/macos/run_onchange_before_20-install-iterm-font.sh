#!/usr/bin/env bash

function iterm_get() {
  /usr/libexec/PlistBuddy -c "Print :$1" ~/Library/Preferences/com.googlecode.iterm2.plist
}

function install_iterm_font() {
    local font_base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
    if [ "$TERM_PROGRAM" != "iTerm.app" ]; then
        return 0
    fi
    [ -x "/usr/libexec/PlistBuddy" ]
    [ -x "/usr/bin/plutil" ]
    [ -x "/usr/bin/defaults" ]
    [ -f "$HOME/Library/Preferences/com.googlecode.iterm2.plist" ]
    [ -r "$HOME/Library/Preferences/com.googlecode.iterm2.plist" ]
    [ -w "$HOME/Library/Preferences/com.googlecode.iterm2.plist" ]
    local guid1="$(iterm_get '"Default Bookmark Guid"' 2>/dev/null)"
    local guid2="$(iterm_get '"New Bookmarks":0:"Guid"' 2>/dev/null)"
    local font="$(iterm_get '"New Bookmarks":0:"Normal Font"' 2>/dev/null)"
    [ "$guid1" = "$guid2" ]
    [[ $font != "MesloLGS-NF-Regular "* ]] || return 0
    # Download fonts
    command mkdir -p "$HOME/Library/Fonts"
    local style
    for style in Regular Bold Italic 'Bold Italic'; do
        local file="MesloLGS NF ${style}.ttf"
        curl -fsSL -o "$HOME/Library/Fonts/$file.tmp" "$font_base_url/${file// /%20}"
        command mv -f "$HOME/Library/Fonts/$file"{.tmp,}
    done
    local settings=(
        '"Normal Font"',string,'"MesloLGS-NF-Regular 14"'
        '"Terminal Type"',string,'"xterm-256color"'
        '"Horizontal Spacing"',real,1
        '"Vertical Spacing"',real,1
        '"Minimum Contrast"',real,0
        '"Use Bold Font"',bool,1
        '"Use Bright Bold"',bool,1
        '"Use Italic Font"',bool,1
        '"ASCII Anti Aliased"',bool,1
        '"Non-ASCII Anti Aliased"',bool,1
        '"Use Non-ASCII Font"',bool,0
        '"Ambiguous Double Width"',bool,0
        '"Draw Powerline Glyphs"',bool,1
        '"Only The Default BG Color Uses Transparency"',bool,1
        '"Show Mark Indicators"',bool,0
    )
    for row in "${settings[@]}"; do
        local oldIFS="$IFS"
        IFS=","
        set -- $row
        IFS="$oldIFS"
        local key=$1 type=$2 value=$3
        /usr/libexec/PlistBuddy -c "Set :\"New Bookmarks\":0:$key $value" \
            ~/Library/Preferences/com.googlecode.iterm2.plist 2>/dev/null && continue
        /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:$key $type $value" \
            ~/Library/Preferences/com.googlecode.iterm2.plist
    done
    /usr/bin/defaults read com.googlecode.iterm2 > /dev/null
}

install_iterm_font
