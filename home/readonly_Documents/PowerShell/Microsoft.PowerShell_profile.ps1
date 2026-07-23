[Console]::OutputEncoding = [Text.Encoding]::UTF8

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
oh-my-posh init pwsh --config ~/Documents/ohmyposh-themes/thecyberden.omp.json | Invoke-Expression

# Environment
$env:BAT_PAGER = "ov"
$env:BAT_THEME = "1337"
$env:EZA_CONFIG_DIR="$HOME\.config\eza"
$env:TEALDEER_CONFIG_DIR="$HOME\.config\tealdeer"

# Delayed modules load. The child runspace only WARMS the module files
# (disk/assembly cache) so the deferred init below imports them fast in
# the main session; it is a latency optimization, not a correctness
# dependency.
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

# Runs exactly once, whichever of the two triggers below fires first.
$global:__DeferredProfileInit = {
    if ($global:__DeferredProfileInitDone) { return }
    $global:__DeferredProfileInitDone = $true

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
    Unregister-Event -SourceIdentifier DeferredProfileLoad -ErrorAction SilentlyContinue
    $DelayedLoadProfile.Dispose()
    $DelayedLoadProfileRunspace.Close()
    $DelayedLoadProfileRunspace.Dispose()
}

# Guard on a terminal state: InvocationStateChanged also fires for the
# NotStarted->Running transition, and disposing a still-running pipeline
# would stop it mid-import.
$null = Register-ObjectEvent -InputObject $DelayedLoadProfile -EventName InvocationStateChanged -SourceIdentifier DeferredProfileLoad -Action {
    if ($EventArgs.InvocationStateInfo.State -in 'Completed', 'Failed', 'Stopped') {
        & $global:__DeferredProfileInit
    }
}

# If the pipeline already reached a terminal state before the
# subscription landed (instant Import-Module failure on a fresh machine,
# or an unusually fast completion), that event is gone forever — run the
# init now instead of never.
if ($DelayedLoadProfile.InvocationStateInfo.State -in 'Completed', 'Failed', 'Stopped') {
    & $global:__DeferredProfileInit
}
