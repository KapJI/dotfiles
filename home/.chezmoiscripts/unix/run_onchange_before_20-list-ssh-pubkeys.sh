#!/bin/sh

OUTPUT="${HOME}/.config/chezmoi/ssh_pubkeys.txt"

error() {
    echo "Error: $1"
    exit 1
}

ssh-add -L > $OUTPUT
grep "Github SSH Key" "$OUTPUT" > /dev/null || error "Github key is not found"
chmod 600 "$OUTPUT"
