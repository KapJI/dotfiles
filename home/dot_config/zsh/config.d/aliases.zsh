# Aliases
alias fd="fd --hidden"
alias hgsl="hg sl"
alias ls="eza --icons=always --group --all"
alias lt="eza --icons=always --tree --all"
alias l="eza --icons=always -l --group --all"
alias mosh="mosh -6"
alias runp="lsof -i"
alias sl="subl"
alias sudo="sudo " # hack to make these aliases available for sudo
alias usage="du -h -d1 | sort -h"
alias vim="nvim"
alias czm="chezmoi"

# Git aliases from oh-my-zsh
alias g="git"
alias ga="git add"
alias gb="git branch"
alias gco="git checkout"
alias gcl="git clone"
alias gc="git commit"
alias gcam="git commit --all --message"
alias gcm="git commit --message"
alias gcn!="git commit --verbose --no-edit --amend"
alias gd="git diff"
alias gf="git fetch"
alias gl="git pull"
alias gpra="git pull --rebase --autostash"
alias gp="git push"
alias gpf!="git push --force"
alias grb="git rebase"
alias gr="git remote"
alias grs="git restore"
alias grm="git rm"
alias gsh="git show"
alias gst="git status"

# https://github.com/sharkdp/bat
alias bathelp='bat --plain --language=help'
help() {
    "$@" --help 2>&1 | bathelp
}
