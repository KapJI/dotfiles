# Required for gpg sign
export CURRENT_TTY="$TTY"
export GPG_TTY="$CURRENT_TTY"

# Set editor for zsh-vi-mode
export EDITOR="nvim"
export ZVM_VI_EDITOR="nvim"

# added by setup_fb4a.sh
if [ "$MACOS" = true ]; then
    export ANDROID_SDK=/opt/android_sdk
    export ANDROID_NDK_REPOSITORY=/opt/android_ndk
    export ANDROID_HOME=${ANDROID_SDK}
    export PATH=${PATH}:${ANDROID_SDK}/emulator:${ANDROID_SDK}/tools:${ANDROID_SDK}/tools/bin:${ANDROID_SDK}/platform-tools
fi
