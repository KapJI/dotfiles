Remove-Item -Force Alias:sl
function global:sl {
    if ($MyInvocation.ExpectingInput) {
        $input | & subl.exe $args
    } else {
        & subl.exe $args
    }
}

function global:vim {
    if ($MyInvocation.ExpectingInput) {
        $input | & nvim.exe $args
    } else {
        & nvim.exe $args
    }
}

function global:czm {
    if ($MyInvocation.ExpectingInput) {
        $input | & chezmoi.exe $args
    } else {
        & chezmoi.exe $args
    }
}

function global:czmcd {
    cd $(chezmoi source-path)
}



function global:fd {
    if ($MyInvocation.ExpectingInput) {
        $input | & fd.exe --hidden $args
    } else {
        & fd.exe --hidden $args
    }
}

function global:rg {
    if ($MyInvocation.ExpectingInput) {
        $input | & rg.exe --hidden $args
    } else {
        & rg.exe --hidden $args
    }
}

# Git aliases from oh-my-zsh
function global:g {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe $args
    } else {
        & git.exe $args
    }
}

function global:ga {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe add $args
    } else {
        & git.exe add $args
    }
}

function global:gb {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe branch $args
    } else {
        & git.exe branch $args
    }
}

Remove-Item -Force Alias:gc
function global:gc {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe commit $args
    } else {
        & git.exe commit $args
    }
}

function global:gco {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe checkout $args
    } else {
        & git.exe checkout $args
    }
}

function global:gcl {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe clone $args
    } else {
        & git.exe clone $args
    }
}

function global:gcam {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe commit --all --message $args
    } else {
        & git.exe commit --all --message $args
    }
}

Remove-Item -Force Alias:gcm
function global:gcm {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe commit --message $args
    } else {
        & git.exe commit --message $args
    }
}

function global:gcn! {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe commit --verbose --no-edit --amend $args
    } else {
        & git.exe commit --verbose --no-edit --amend $args
    }
}

function global:gcan! {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe commit --verbose --all --no-edit --amend $args
    } else {
        & git.exe commit --verbose --all --no-edit --amend $args
    }
}

function global:gd {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe diff $args
    } else {
        & git.exe diff $args
    }
}

function global:gds {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe diff $args
    } else {
        & git.exe diff --staged $args
    }
}

function global:gf {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe fetch $args
    } else {
        & git.exe fetch $args
    }
}

function global:gpl {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe pull $args
    } else {
        & git.exe pull $args
    }
}

function global:gplra {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe pull --rebase --autostash $args
    } else {
        & git.exe pull --rebase --autostash $args
    }
}

Remove-Item -Force Alias:gp
function global:gp {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe push $args
    } else {
        & git.exe push $args
    }
}

function global:gpf! {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe push --force $args
    } else {
        & git.exe push --force $args
    }
}

function global:gr {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe remote $args
    } else {
        & git.exe remote $args
    }
}

function global:grb {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe rebase $args
    } else {
        & git.exe rebase $args
    }
}

function global:grs {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe restore $args
    } else {
        & git.exe restore $args
    }
}

function global:grm {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe rm $args
    } else {
        & git.exe rm $args
    }
}

function global:gsh {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe show $args
    } else {
        & git.exe show $args
    }
}

function global:gst {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe status $args
    } else {
        & git.exe status $args
    }
}

function global:gsl {
    if ($MyInvocation.ExpectingInput) {
        $input | & git.exe sl $args
    } else {
        & git.exe sl $args
    }
}

# eza
Remove-Item -Force Alias:ls
function global:ls {
    if ($MyInvocation.ExpectingInput) {
        $input | & eza.exe --icons=always --all $args
    } else {
        & eza.exe --icons=always --all $args
    }
}

function global:lt {
    if ($MyInvocation.ExpectingInput) {
        $input | & eza.exe --icons=always --tree --all $args
    } else {
        & eza.exe --icons=always --tree --all $args
    }
}

function global:l {
    if ($MyInvocation.ExpectingInput) {
        $input | & eza.exe --icons=always --long --all $args
    } else {
        & eza.exe --icons=always --long --all $args
    }
}

# Useful functions for Unix-like tools
function global:df {
    Get-Volume $args
}

function global:head {
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

function global:tail {
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

function global:which ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function global:touch {
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

function global:bathelp {
    if ($MyInvocation.ExpectingInput) {
        $input | & bat.exe -l help --plain $args
    } else {
        & bat.exe -l help --plain $args
    }
}
