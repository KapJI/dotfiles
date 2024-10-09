# Install ssh agent config
mkdir $env:USERPROFILE\AppData\Local\1Password\config\ssh\
cp $(& $env:USERPROFILE\.local\bin\chezmoi source-path)\.chezmoitemplates\1password_agent.toml $env:USERPROFILE\AppData\Local\1Password\config\ssh\agent.toml
winget install -e --id AgileBits.1Password
winget install -e --id Microsoft.PowerShell
