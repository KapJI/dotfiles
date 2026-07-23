# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOS=true
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/os-release ]; then
        # Anonymous function + subshell-sourcing so os-release's
        # NAME/VERSION_ID/PRETTY_NAME/... don't leak into every shell;
        # only the distro flags escape via typeset -g.
        () {
            local id="$(. /etc/os-release && echo "$ID")"
            case $id in
                centos)
                    typeset -g CENTOS=true
                    ;;
                debian|ubuntu|pop)
                    typeset -g DEBIAN_BASED=true
                    ;;
                nixos)
                    # Supported (see reload() in aliases.zsh); no flag needed.
                    ;;
                *)
                    echo "ERROR: running on unknown Linux distro: ${id}!"
                    ;;
            esac
        }
    else
        echo "ERROR: can't detect Linux distro!"
    fi
else
    echo "ERROR: running on unknown OS: ${OSTYPE}!"
fi
