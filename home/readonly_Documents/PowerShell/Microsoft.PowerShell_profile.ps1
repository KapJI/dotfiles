[Console]::OutputEncoding = [Text.Encoding]::UTF8
$env:Path += ";$env:USERPROFILE\.local\bin"

$env:VIRTUAL_ENV_DISABLE_PROMPT=1
oh-my-posh init pwsh --config ~/Documents/ohmyposh-themes/thecyberden.omp.json | Invoke-Expression
$env:POSH_GIT_ENABLED = $true
# Import-Module -Name Terminal-Icons
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Ctrl+u -Function BackwardDeleteLine
Set-PSReadLineKeyHandler -Key Ctrl+k -Function ForwardDeleteLine
Invoke-Expression (& { (zoxide init powershell | Out-String) })
# Aliases
Remove-Item -Force Alias:sl
New-Alias sl subl
New-Alias vim nvim
New-Alias czm chezmoi
# fzf
$env:FZF_DEFAULT_OPTS="--ansi --height=40% --layout=reverse"
Import-Module posh-git
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

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
        $input | Select-Object -Last $n
    }
}

function df {
    get-volume
}

function which ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}
