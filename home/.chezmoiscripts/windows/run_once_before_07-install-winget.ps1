$progressPreference = 'silentlyContinue'
Write-Information "Downloading WinGet and its dependencies..."
Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile $env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile $env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx
Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx -OutFile $env:TEMP\Microsoft.UI.Xaml.2.8.x64.appx
Add-AppxPackage $env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx
Add-AppxPackage $env:TEMP\Microsoft.UI.Xaml.2.8.x64.appx
Add-AppxPackage $env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
