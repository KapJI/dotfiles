[Console]::OutputEncoding = [Text.Encoding]::UTF8

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
oh-my-posh init pwsh --config ~/Documents/ohmyposh-themes/thecyberden.omp.json | Invoke-Expression
$env:POSH_GIT_ENABLED = $true
$env:BAT_PAGER = "ov"
$env:BAT_THEME = "1337"
# Enable Zsh like completion
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
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
Add-Alias czmcd "cd $(chezmoi source-path)"
# Git aliases from oh-my-zsh
New-Alias g git
# Add-Alias requires running `Install-Module -Name posh-alias`
Add-Alias ga "git add"
Add-Alias gb "git branch"
Remove-Item -Force Alias:gc
Add-Alias gc "git commit"
Add-Alias gco "git checkout"
Add-Alias gcl "git clone"
Add-Alias gcam "git commit --all --message"
Remove-Item -Force Alias:gcm
Add-Alias gcm "git commit --message"
Add-Alias gcn! "git commit --verbose --no-edit --amend"
Add-Alias gcan! "git commit --verbose --all --no-edit --amend"
Add-Alias gd "git diff"
Add-Alias gf "git fetch"
Add-Alias gpl "git pull"
Add-Alias gplra "git pull --rebase --autostash"
Remove-Item -Force Alias:gp
Add-Alias gp "git push"
Add-Alias gpf! "git push --force"
Add-Alias gr "git remote"
Add-Alias grb "git rebase"
Add-Alias grs "git restore"
Add-Alias grm "git rm"
Add-Alias gsh "git show"
Add-Alias gst "git status"
Add-Alias gsl "git sl"
# fzf
$env:FZF_DEFAULT_OPTS="--ansi --height=40% --layout=reverse"
Import-Module posh-git
Import-Module Terminal-Icons
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
        # If no path is provided, read from stdin
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

function fd {
    fd.exe --hidden $args
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

# Load completion
. $HOME\Documents\Powershell\Completion\chezmoi.ps1
Register-ArgumentCompleter -CommandName 'czm' -ScriptBlock ${__chezmoiCompleterBlock}
. $HOME\Documents\Powershell\Completion\delta.ps1
. $HOME\Documents\Powershell\Completion\ov.ps1
