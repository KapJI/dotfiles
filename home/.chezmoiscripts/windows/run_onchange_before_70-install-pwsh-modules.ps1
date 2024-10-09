# Reload Path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

pwsh -NoProfile -NoLogo -Command 'Install-Module -Name posh-alias -Repository PSGallery -Scope CurrentUser -Confirm:$False -Force'
