# Reload Path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Update nvim plugins
nvim +PlugUpgrade +PlugUpdate +qall
