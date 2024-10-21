#!/bin/sh

if ! command -v brew &> /dev/null; then
    brew_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    /bin/bash -c "$(curl -fsSL ${brew_url})"
fi

# Make sure CLI tools are installed.
while xcode-select --install 2>/dev/null; do
    echo "Waiting before Apple CLI tools are installed..."
    sleep 10
done
