if [ "$MACOS" = true ]; then
    # Open man page as PDF
    function manpdf() {
        man -t "${1}" | open -f -a /System/Applications/Preview.app/
    }

    # Change working directory to the top-most Finder window location
    function cdf() { # short for `cdfinder`
        cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')";
    }
fi

if [ "$MACOS" = true ]; then
    _BUCK_COMPLETION_MODES="mac opt-mac macpy"
else
    _BUCK_COMPLETION_MODES="dev opt"
fi
