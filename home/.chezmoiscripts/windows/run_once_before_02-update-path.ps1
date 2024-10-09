$currentProfile = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)

if ($currentProfile -notlike "*$env:USERPROFILE\.local\bin*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        $currentProfile + ";$env:USERPROFILE\.local\bin",
        [EnvironmentVariableTarget]::User)
}
