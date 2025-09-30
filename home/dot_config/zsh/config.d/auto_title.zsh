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
  title "$short" "$full_pwd"
}

add-zsh-hook precmd _set_term_title_precmd
