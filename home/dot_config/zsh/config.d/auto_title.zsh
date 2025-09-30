# Display $1 in terminal title.
_set_term_title() {
  emulate -L zsh
  if [[ -t 1 ]]; then
    print -rn -- $'\e]0;'${(V)1}$'\a'
  elif [[ -w $TTY ]]; then
    print -rn -- $'\e]0;'${(V)1}$'\a' >$TTY
  fi
}

# When no command is running, display the current directory in the terminal title.
_set_term_title_precmd() {
  local max_length=20
  # Replace home with '~'
  local full_pwd=$(print -P "%~")
  local short

  if (( ${#full_pwd} <= max_length )); then
    short=$full_pwd
  else
    if (( $+functions[shrink_path] )); then
        short=$(shrink_path -f -3)
    else
        short=$full_pwd
    fi
  fi
  _set_term_title "$short"
}

add-zsh-hook precmd _set_term_title_precmd
