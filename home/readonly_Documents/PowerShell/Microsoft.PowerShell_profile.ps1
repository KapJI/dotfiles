[Console]::OutputEncoding = [Text.Encoding]::UTF8

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
oh-my-posh init pwsh --config ~/Documents/ohmyposh-themes/thecyberden.omp.json | Invoke-Expression

# Environment
$env:BAT_PAGER = "ov"
$env:BAT_THEME = "1337"

# Delayed modules load
$DelayedLoadProfileRunspace = [RunspaceFactory]::CreateRunspace()
$DelayedLoadProfile = [PowerShell]::Create()
$DelayedLoadProfile.Runspace = $DelayedLoadProfileRunspace
$DelayedLoadProfileRunspace.Open()
[void]$DelayedLoadProfile.AddScript({
    # Preload modules
    Import-Module posh-alias
    Import-Module PSFzf
    Import-Module PSReadLine
})
[void]$DelayedLoadProfile.BeginInvoke()
$null = Register-ObjectEvent -InputObject $DelayedLoadProfile -EventName InvocationStateChanged -Action {
    # Enable Zsh like completion
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Ctrl+u -Function BackwardDeleteLine
    Set-PSReadLineKeyHandler -Key Ctrl+k -Function ForwardDeleteLine

    . $HOME\Documents\Powershell\aliases.ps1

    # Init modules
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
    $env:FZF_DEFAULT_OPTS="--ansi --height=40% --layout=reverse"
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

    # Load completion
    . $HOME\Documents\Powershell\Completion\chezmoi.ps1
    Register-ArgumentCompleter -CommandName 'czm' -ScriptBlock ${__chezmoiCompleterBlock}
    . $HOME\Documents\Powershell\Completion\delta.ps1
    . $HOME\Documents\Powershell\Completion\ov.ps1
    . $HOME\Documents\Powershell\Completion\ruff.ps1

    # Cleanup
    $DelayedLoadProfile.Dispose()
    $DelayedLoadProfileRunspace.Close()
    $DelayedLoadProfileRunspace.Dispose()
}

function head {
    param(
        [string]$Path,
        [int]$n = 10
    )

    if ($Path -ne "") {
        Get-Content $Path -Head $n
    } else {
        $input | Select-Object -First $n
    }
}

function tail {
    param(
        [string]$Path,
        [int]$n = 10
    )

    if ($Path -ne "") {
        Get-Content $Path -Tail $n
    } else {
        # If no path is provided, read from stdin
        $input | Select-Object -Last $n
    }
}

function which ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function bathelp {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string]$InputObject
    )
    begin {
        $content = @()
    }
    process {
        $content += $InputObject
    }
    end {
        $content -join "`n" | bat.exe -l help --plain
    }
}

function touch {
    param (
        [string[]]$Paths
    )

    foreach ($Path in $Paths) {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -ItemType File
        } else {
            # Update the last write time if the file already exists
            (Get-Item $Path).LastWriteTime = Get-Date
        }
    }
}
