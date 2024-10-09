if (-not (Get-Command "scoop" -ErrorAction SilentlyContinue | Test-Path)) {
    Write-Host "Installing scoop..."
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
} else {
    Write-Host "scoop is installed"
}
