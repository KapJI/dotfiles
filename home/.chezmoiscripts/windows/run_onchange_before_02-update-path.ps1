$currentProfile = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)

if ($currentProfile -notlike "*$env:USERPROFILE\.local\bin*") {
    $currentProfile += ";$env:USERPROFILE\.local\bin"
}

if ($currentProfile -notlike "*$env:ProgramFiles\Sublime Text*") {
    $currentProfile += ";$env:ProgramFiles\Sublime Text"
}

[Environment]::SetEnvironmentVariable(
    "Path",
    $currentProfile,
    [EnvironmentVariableTarget]::User)
