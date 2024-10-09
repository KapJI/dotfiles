# Install ssh agent config
$path = "$env:USERPROFILE\AppData\Local\1Password\config\ssh"
if (!(Test-Path -PathType container $path)) {
      New-Item -ItemType Directory -Path $path
}
$sourcePath = & $env:USERPROFILE\.local\bin\chezmoi source-path
cp "$sourcePath/.chezmoitemplates/1password_agent.toml" $path\agent.toml
winget install -e --id AgileBits.1Password
winget install -e --id Microsoft.PowerShell
