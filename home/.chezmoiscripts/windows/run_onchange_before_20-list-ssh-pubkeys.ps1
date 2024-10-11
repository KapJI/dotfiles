# Reload Path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install ssh agent config
$configDir = "$env:USERPROFILE\AppData\Local\1Password\config\ssh"
if (!(Test-Path -PathType container $configDir)) {
      New-Item -ItemType Directory -Path $configDir
}
$sourcePath = chezmoi source-path
cp "$sourcePath/.chezmoitemplates/1password_agent.toml" $configDir\agent.toml

$OUTPUT = "$HOME\.config\chezmoi\ssh_pubkeys.txt"

for ($i = 0; $i -le 5; $i++) {
    $keys = ssh-add -L
    if ($keys | Select-String -Pattern "Github SSH Key") {
        break
    }
    Read-Host -Prompt "Github key is not found. Check that SSH Agent in 1Password is running and press any key to continue"
}

$stream = New-Object System.IO.StreamWriter($OUTPUT, $false, [System.Text.Encoding]::ASCII)
$stream.NewLine = "`n"
foreach ($line in $keys) {
    $stream.WriteLine($line)
}
$stream.Close()

# Set permissions so only the current user has read and write access
$user = "$env:USERDOMAIN\$env:USERNAME"
icacls $OUTPUT /inheritance:r /grant:r "${user}:(R,W)"
