#!/bin/sh

OUTPUT="$HOME/.config/chezmoi/key.txt"

if [ ! -f "$OUTPUT" ]; then
    mkdir -p "${HOME}/.config/chezmoi"
    chezmoi age decrypt --output "$OUTPUT" --passphrase "$(chezmoi source-path)/key.txt.age"
    chmod 600 "$OUTPUT"
fi
