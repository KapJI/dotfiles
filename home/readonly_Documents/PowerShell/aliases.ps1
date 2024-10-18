# Add-Alias requires module "posh-alias"
Import-Module posh-alias

Remove-Item -Force Alias:sl
Add-Alias sl subl
Add-Alias vim nvim
Add-Alias czm chezmoi
Add-Alias czmcd "cd $(chezmoi source-path)"
Add-Alias df Get-Volume
Add-Alias fd "fd.exe --hidden"
Add-Alias rg "rg.exe --hidden"

# Git aliases from oh-my-zsh
Add-Alias g git
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

# eza
Remove-Item -Force Alias:ls
Add-Alias ls "eza --icons=always --all"
Add-Alias lt "eza --icons=always --tree --all"
Add-Alias l "eza --icons=always -l --all"
