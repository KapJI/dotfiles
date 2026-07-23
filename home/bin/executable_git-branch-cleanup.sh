#!/bin/bash

GREEN="$(tput setaf 2)$(tput bold)"
NC="$(tput sgr 0)"

current=$(git branch --show-current)
branches=()
while IFS= read -r branch; do
    # Skip protected branches (exact match) and the checked-out one.
    case "$branch" in
        master|main|dev) continue ;;
    esac
    [ "$branch" = "$current" ] && continue
    branches+=("$branch")
done < <(git branch --format='%(refname:short)')

for branch in "${branches[@]}"; do
    while true; do
        read -p "Delete branch ${GREEN}$branch${NC}? [y/N] " answer
        case "$answer" in
            [yY]|[yY][eE][sS])
                git branch -d "$branch" || true
                break
                ;;
            [nN]|[nN][oO]|"")
                break
                ;;
            *)
                printf %s\\n "Please answer yes or no."
        esac
    done
done

if [ "${#branches[@]}" -eq 0 ]; then
    echo "No branches to delete"
fi
