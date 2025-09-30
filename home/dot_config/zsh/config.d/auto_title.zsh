# Display $1 in terminal title.
function set-term-title() {
  emulate -L zsh
  if [[ -t 1 ]]; then
    print -rn -- $'\e]0;'${(V)1}$'\a'
  elif [[ -w $TTY ]]; then
    print -rn -- $'\e]0;'${(V)1}$'\a' >$TTY
  fi
}

# When a command is running, display it in the terminal title.
function set-term-title-preexec() {
  set-term-title "${1%% *}"
}

# When no command is running, display the current directory in the terminal title.
function set-term-title-precmd() {
  local short
  if (( $+functions[shrink_path] )); then
    short=$(shrink_path -f -3)
  else
    short=${PWD/#$HOME/~}
  fi
  set-term-title "${short}"
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec set-term-title-preexec
add-zsh-hook precmd set-term-title-precmd
