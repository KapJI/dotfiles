# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOS=true
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            centos)
                CENTOS=true
                ;;
            debian|ubuntu|pop)
                DEBIAN_BASED=true
                ;;
            nixos)
                # Supported (see reload() in aliases.zsh); no flag needed.
                ;;
            *)
                echo "ERROR: running on unknown Linux distro: ${ID}!"
                ;;
        esac
    else
        echo "ERROR: can't detect Linux distro!"
    fi
else
    echo "ERROR: running on unknown OS: ${OSTYPE}!"
fi
