#!/usr/bin/env bash
#
# Custom macOS settings, captured from the main Mac: trackpad, keyboard,
# system shortcuts, Dock, Finder, screenshots, menu-bar clock, Time Machine
# exclusions. Only values that differ from a fresh install are written. Re-runs
# when this file changes; to capture a new setting, find its key (`defaults
# read <domain>` before and after changing it in System Settings) and add a
# line here.
#
# The Мефодица layout and the input-source list are set by
# run_onchange_after_71-setup-keyboard-layout; press-and-hold by before_60.

set -eu

# Trackpad, built-in and Bluetooth: tap to click, light click, three-finger
# tap (Look Up) off.
for d in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    defaults write "$d" Clicking -bool true
    defaults write "$d" FirstClickThreshold -int 0
    defaults write "$d" SecondClickThreshold -int 0
    defaults write "$d" TrackpadThreeFingerTapGesture -int 0
done
defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1
defaults write -g com.apple.trackpad.scaling -float 0.875
defaults write -g com.apple.mouse.scaling -float 1.5
defaults write -g AppleEnableSwipeNavigateWithScrolls -bool false

# Keyboard: fast key repeat, no autocorrect, capitals or double-space period;
# the fn/globe key does nothing.
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 25
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g WebAutomaticSpellingCorrectionEnabled -bool false
defaults write com.apple.HIToolbox AppleFnUsageType -int 0

# Appearance follows the time of day.
defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool true

# System shortcuts (Keyboard > Keyboard Shortcuts): hotkey <id> <on> [key
# code modifiers]. Parameters are the character (65535 for none), the virtual
# key code and the modifier mask.
hotkey() {
    local id=$1 on=false value=""
    [ "$2" = 1 ] && on=true
    if [ $# -gt 2 ]; then
        value="<key>value</key><dict><key>parameters</key><array><integer>$3</integer><integer>$4</integer><integer>$5</integer></array><key>type</key><string>standard</string></dict>"
    fi
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" \
        "<dict><key>enabled</key><$on/>$value</dict>"
}
for id in 15 16 17 18 19 20 21 22 23 24 25 26; do hotkey "$id" 0; done # Accessibility zoom
hotkey 60 0 32 49 262144             # Select the previous input source: ^Space
hotkey 61 0 32 49 786432             # Select next source in Input menu: ^⌥Space
hotkey 64 0 32 49 1048576            # Spotlight: ⌘Space
hotkey 79 1                          # Mission Control: move left a space
hotkey 80 1
hotkey 81 1                          # Mission Control: move right a space
hotkey 82 1
hotkey 164 0 65535 65535 0
hotkey 176 0
hotkey 240 0 65535 123 8650752       # Window tiling: fn^← left half
hotkey 241 0 65535 124 8650752       # fn^→ right half
hotkey 242 1 65535 126 8650752       # fn^↑ top half
hotkey 243 1 65535 125 8650752       # fn^↓ bottom half

# Dock: autohide with no delay, scale effect.
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock tilesize -int 62
defaults write com.apple.dock mineffect -string scale

# Mission Control: group windows by application.
defaults write com.apple.WindowManager AppWindowGroupingBehavior -bool true

# Finder: column view, grouped by kind.
defaults write com.apple.finder FXPreferredViewStyle -string clmv
defaults write com.apple.finder FXPreferredGroupBy -string Kind

# Screenshots and recordings go to ~/Pictures/Screenshots.
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

# Menu-bar clock: analog, no date or weekday.
defaults write com.apple.menuextra.clock IsAnalog -bool true
defaults write com.apple.menuextra.clock ShowDate -int 2
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool false

# Time Machine skips ~/.cache, which holds only caches. chezmoi's httpcache
# there names files after base64-encoded download URLs, and signed GitHub
# release URLs make full paths longer than macOS's 1024-byte limit, which
# Time Machine reports as "could not be backed up". The exclusion is sticky.
mkdir -p "$HOME/.cache"
tmutil addexclusion "$HOME/.cache"

# Apply without logging out: shortcuts and keyboard via activateSettings, the
# rest by restarting the apps that read them. Trackpad clicking and key repeat
# still need a logout on a fresh Mac.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
killall Dock Finder SystemUIServer 2>/dev/null || true
echo "macos-defaults: applied; log out and back in for trackpad and key repeat."
