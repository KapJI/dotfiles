$CONFIG_DIR = "$HOME\.config\chezmoi"
$OUTPUT = "$CONFIG_DIR\key.txt"

if (!(Test-Path $OUTPUT)) {
    # Reload Path
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    # Create the directory if it doesn't exist
    if (!(Test-Path -PathType container $CONFIG_DIR)) {
        New-Item -ItemType Directory -Path $CONFIG_DIR
    }

    # Decrypt the key.txt.age file
    for ($i = 0; $i -le 5; $i++) {
        chezmoi age decrypt --output $OUTPUT --passphrase "$(chezmoi source-path)/key.txt.age"
        if ($?) {
            break
        }
    }

    # Set permissions so only the current user has read and write access
    $user = "$env:USERDOMAIN\$env:USERNAME"
    icacls $OUTPUT /inheritance:r /grant:r "${user}:(R,W)"
}
