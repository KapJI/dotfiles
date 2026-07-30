if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
fi

if [ "$MACOS" = true ]; then
    # 1Password's agent socket lives at this fixed path. Export it
    # unconditionally — even when 1Password isn't running yet (fresh login,
    # or the agent stopped after an app update): the path is stable, so the
    # moment the agent comes up this already-running shell's SSH_AUTH_SOCK is
    # live with no reload. Guarding on socket existence would instead pin
    # whatever was inherited and force a reload once the agent starts. Same
    # self-heal idea as the stable-symlink path in the Linux branch below.
    export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
elif [ -S "$HOME/.1password/agent.sock" ]; then
    # Linux with 1Password running: use its agent directly. Anything inherited
    # (wezterm's own agent, ssh-forwarded sockets) is overridden.
    export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
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
fi
