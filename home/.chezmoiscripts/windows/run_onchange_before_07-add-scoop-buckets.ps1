# Reload Path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

scoop bucket add extras
scoop bucket add nerd-fonts
