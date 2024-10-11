# Enable-Symlinks.ps1
# This script enables symlink creation for non-admin users on Windows 11 by enabling Developer Mode.
# It elevates permissions if necessary and waits for user input before exiting the elevated script.

# Function to check if the script is running as administrator
Function Test-IsAdministrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Registry path and key for Developer Mode
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
$regKey = "AllowDevelopmentWithoutDevLicense"

# Check if Developer Mode is already enabled
$devModeEnabled = $false
if (Test-Path $regPath) {
    $value = Get-ItemProperty -Path $regPath -Name $regKey -ErrorAction SilentlyContinue
    if ($value -and $value.$regKey -eq 1) {
        $devModeEnabled = $true
    }
}

if ($devModeEnabled) {
    Write-Host "Developer Mode is already enabled. Symlinks are enabled for non-admin users."
    exit
}

# If not running as administrator, restart the script with elevated privileges and wait
if (-not (Test-IsAdministrator)) {
    Write-Host "Elevating permissions to administrator..."
    Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`"" `
        -Verb RunAs -Wait
    Write-Host "Elevation completed. Resuming script..."
    exit
}

Write-Host "Enabling Developer Mode to allow symlink creation for non-admin users..."
# Create the registry key if it doesn't exist
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# Enable Developer Mode by setting the registry value
try {
    Set-ItemProperty -Path $regPath -Name $regKey -Type DWord -Value 1
    Write-Host "Developer Mode enabled successfully. Symlinks are now enabled for non-admin users."
} catch {
    Write-Error "Failed to enable Developer Mode: $_"
}

# Wait for user input before exiting
Write-Host
Read-Host -Prompt "Press Enter to exit"
