# Reload Path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$OUTPUT = "$HOME\.config\chezmoi\ssh_pubkeys.txt"

$keys = ssh-add -L

$stream = New-Object System.IO.StreamWriter($OUTPUT, $false, [System.Text.Encoding]::ASCII)
$stream.NewLine = "`n"
foreach ($line in $keys) {
    $stream.WriteLine($line)
}
$stream.Close()

if (!(Select-String -Pattern "Github SSH Key" -Path $OUTPUT)) {
    Write-Error "Error: Github key is not found"
    exit 1
}

# Set permissions so only the current user has read and write access
$user = "$env:USERDOMAIN\$env:USERNAME"
icacls $OUTPUT /inheritance:r /grant:r "${user}:(R,W)"
