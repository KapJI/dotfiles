#!/bin/bash

branches=($(git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE branch --merged | egrep -v "(^\*|master|main|dev)"))

for branch in "${branches[@]}"; do
    while true; do
        read -p "Delete branch '$branch'? [y/N] " answer
        case "$answer" in
            [yY]|[yY][eE][sS])
                git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE branch -d "$branch"
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
    echo "No merged branches to delete"
fi