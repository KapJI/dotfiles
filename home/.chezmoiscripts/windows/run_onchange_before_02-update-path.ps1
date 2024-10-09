$currentProfile = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)

if ($currentProfile -notlike "*$env:USERPROFILE\.local\bin*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        $currentProfile + ";$env:USERPROFILE\.local\bin;$env:ProgramFiles\Sublime Text",
        [EnvironmentVariableTarget]::User)
}

if ($currentProfile -notlike "*$env:ProgramFiles\Sublime Text*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        $currentProfile + ";$env:ProgramFiles\Sublime Text",
        [EnvironmentVariableTarget]::User)
}
