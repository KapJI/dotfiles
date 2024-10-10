#!/bin/sh

OUTPUT="$HOME/.config/chezmoi/key.txt"

if [ ! -f "$OUTPUT" ]; then
    mkdir -p "${HOME}/.config/chezmoi"
    for i in {1..5}; do
        if chezmoi age decrypt --output "$OUTPUT" --passphrase "$(chezmoi source-path)/key.txt.age"; then
            break
        fi
    done
    chmod 600 "$OUTPUT"
fi
