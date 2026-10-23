# Git aliases, originally from oh-my-zsh; the git-side ones are in
# ~/.config/git/config. Plain zsh with no dependencies, because it is also
# copied to hosts without these dotfiles: the OpenShell agent sandboxes
# (infra-agents refresh) and the routers (router-config), whose zshrc sources it.
alias g="git"
alias ga="git add"
alias gb="git branch"
alias gc="git commit"
alias gco="git checkout"
alias gcl="git clone"
alias gcam="git commit --all --message"
alias gcm="git commit --message"
alias gcn!="git commit --verbose --no-edit --amend"
alias gcan!="git commit --verbose --all --no-edit --amend"
alias gd="git diff"
alias gds="git diff --staged"
alias gf="git fetch"
alias gmv="git mv"
alias gpl="git pull"
alias gplra="git pull --rebase --autostash"
alias gp="git push"
# Safe force-push default: --force-with-lease refuses to clobber remote
# commits you haven't fetched; --force-if-includes additionally requires
# your local ref to include the remote tip. gpf! stays as the raw,
# no-questions-asked escape hatch.
alias gpf="git push --force-with-lease --force-if-includes"
alias gpf!="git push --force"
alias gr="git remote"
alias grb="git rebase"
alias grs="git restore"
alias grm="git rm"
alias gsh="git show"
alias gst="git status"
alias gsl="git sl"
