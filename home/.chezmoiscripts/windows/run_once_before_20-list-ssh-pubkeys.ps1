$OUTPUT = "$HOME\.config\chezmoi\ssh_pubkeys.txt"

ssh-add -L > $OUTPUT
if (!(Select-String -Pattern "Github SSH Key" -Path $OUTPUT)) {
    Write-Error "Error: Github key is not found"
    exit 1
}

# Set permissions so only the current user has read and write access
$user = "$env:USERDOMAIN\$env:USERNAME"
icacls $OUTPUT /inheritance:r /grant:r "${user}:(R,W)"
