if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
fi

if [ "$MACOS" = true ]; then
    export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
else
    # Update symlink for all tmux tabs
    if [ -S "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/ssh_auth_sock" ]; then
        ln -sf $SSH_AUTH_SOCK "$HOME/.ssh/ssh_auth_sock"
    fi
    export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"

    # Symlinks for remote VSCode
    if [ -S "$VSCODE_IPC_HOOK_CLI" ] && [ "$VSCODE_IPC_HOOK_CLI" != "$HOME/.vscode_sock" ]; then
        ln -sf $VSCODE_IPC_HOOK_CLI "$HOME/.vscode_sock"
    fi
    export VSCODE_IPC_HOOK_CLI="$HOME/.vscode_sock"

    if [ -d "$FB_VSC_BIN_FOLDER" ] && [ "$FB_VSC_BIN_FOLDER" != "$HOME/.fb_vsc_dir" ]; then
        if [ -L "$HOME/.fb_vsc_dir" ]; then
            rm "$HOME/.fb_vsc_dir"
        fi
        ln -sf $FB_VSC_BIN_FOLDER "$HOME/.fb_vsc_dir" || echo "Failed to create vsc_dir symlink from $FB_VSC_BIN_FOLDER"
    fi
    export FB_VSC_BIN_FOLDER="$HOME/.fb_vsc_dir"
fi
