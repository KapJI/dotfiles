$OUTPUT = "$HOME\.config\chezmoi\key.txt"

if (!(Test-Path $OUTPUT)) {
    # Create the directory if it doesn't exist
    New-Item -ItemType Directory -Path "$HOME\.config\chezmoi" -Force

    # Decrypt the key.txt.age file
    chezmoi age decrypt --output $OUTPUT --passphrase "$(chezmoi source-path)/key.txt.age"

    # Set permissions so only the current user has read and write access
    $user = "$env:USERDOMAIN\$env:USERNAME"
    icacls $OUTPUT /inheritance:r /grant:r "${user}:(R,W)"
}
