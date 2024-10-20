[Console]::OutputEncoding = [Text.Encoding]::UTF8

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
oh-my-posh init pwsh --config ~/Documents/ohmyposh-themes/thecyberden.omp.json | Invoke-Expression

# Environment
$env:BAT_PAGER = "ov"
$env:BAT_THEME = "1337"
$env:EZA_CONFIG_DIR="$HOME\.config\eza"

# Delayed modules load
$DelayedLoadProfileRunspace = [RunspaceFactory]::CreateRunspace()
$DelayedLoadProfile = [PowerShell]::Create()
$DelayedLoadProfile.Runspace = $DelayedLoadProfileRunspace
$DelayedLoadProfileRunspace.Open()
[void]$DelayedLoadProfile.AddScript({
    # Preload modules
    Import-Module posh-git
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
    . $HOME\Documents\Powershell\Completion\bat.ps1
    . $HOME\Documents\Powershell\Completion\delta.ps1
    . $HOME\Documents\Powershell\Completion\fd.ps1
    . $HOME\Documents\Powershell\Completion\hyperfine.ps1
    . $HOME\Documents\Powershell\Completion\ov.ps1
    . $HOME\Documents\Powershell\Completion\rg.ps1
    . $HOME\Documents\Powershell\Completion\ruff.ps1
    . $HOME\Documents\Powershell\Completion\uv.ps1
    . $HOME\Documents\Powershell\Completion\uvx.ps1
    # posh-git provides completion for git
    Import-Module posh-git

    # Cleanup
    $DelayedLoadProfile.Dispose()
    $DelayedLoadProfileRunspace.Close()
    $DelayedLoadProfileRunspace.Dispose()
}
