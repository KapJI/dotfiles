# Make Windows treat the hardware clock as UTC.
#
# In a dual-boot setup (Linux + Windows on the same disk), Linux/macOS read
# the RTC as UTC by default. Without this setting, Windows treats the RTC as
# local time and rewrites it on every boot, which then makes Linux see the
# wrong time. Setting RealTimeIsUniversal=1 in the registry tells Windows to
# also use UTC, so the two OSes agree.

Function Test-IsAdministrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'
$regKey = 'RealTimeIsUniversal'

$value = Get-ItemProperty -Path $regPath -Name $regKey -ErrorAction SilentlyContinue
if ($value -and $value.$regKey -eq 1) {
    Write-Host "RTC is already configured as UTC."
    exit
}

if (-not (Test-IsAdministrator)) {
    Write-Host "Elevating permissions to administrator..."
    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`"" `
        -Verb RunAs -Wait
    Write-Host "Elevation completed. Resuming script..."
    exit
}

Write-Host "Setting RealTimeIsUniversal=1 (treat RTC as UTC)..."
try {
    New-ItemProperty -Path $regPath -Name $regKey -PropertyType DWord -Value 1 -Force | Out-Null
    Write-Host "RTC configured as UTC. Reboot for the change to take effect."
} catch {
    Write-Error "Failed to set RealTimeIsUniversal: $_"
    exit 1
}
