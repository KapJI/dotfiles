# Enable-Symlinks.ps1
# This script enables symlink creation for non-admin users on Windows 11 by enabling Developer Mode.
# It elevates permissions if necessary and waits for user input before exiting the elevated script.

# Function to check if the script is running as administrator
Function Test-IsAdministrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Registry path and key for UAC mode
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$regKey = "ConsentPromptBehaviorAdmin"

# Check if UAC is already disabled
$uacDisabled = $false
if (Test-Path $regPath) {
    $value = Get-ItemProperty -Path $regPath -Name $regKey -ErrorAction SilentlyContinue
    if ($value -and $value.$regKey -eq 0) {
        $uacDisabled = $true
    }
}

if ($uacDisabled) {
    Write-Host "UAC prompts are already disabled."
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

Write-Host "Disabling UAC prompts..."
# Create the registry key if it doesn't exist
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# Disable UAC prompts by setting the registry value
try {
    Set-ItemProperty -Path $regPath -Name $regKey -Value 0
    Write-Host "UAC prompts disabled successfully."
} catch {
    Write-Error "Failed to disable UAC prompts: $_"
}

# Wait for user input before exiting
Write-Host
Read-Host -Prompt "Press Enter to exit"
