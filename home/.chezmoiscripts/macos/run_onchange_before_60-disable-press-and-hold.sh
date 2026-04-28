#!/usr/bin/env bash

# Disable press-and-hold accent menu so key repeat works in editors (vim, etc.)
current=$(defaults read -g ApplePressAndHoldEnabled 2>/dev/null || echo "")
if [[ "$current" == "0" ]]; then
    echo "ApplePressAndHoldEnabled already disabled."
else
    echo "Disabling ApplePressAndHoldEnabled..."
    defaults write -g ApplePressAndHoldEnabled -bool false
    echo "Log out and back in for the change to take effect."
fi
