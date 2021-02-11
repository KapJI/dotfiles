#!/bin/bash

git_extra_args=""
if [ ! -z "$GIT_DIR" ]; then
    git_extra_args="$git_extra_args --git-dir=$GIT_DIR"
fi
if [ ! -z "$GIT_WORK_TREE" ]; then
    git_extra_args="$git_extra_args --work-tree=$GIT_WORK_TREE"
fi

branches=($(sh -c "git $git_extra_args branch --merged" | egrep -v "(^\*|master|main|dev)"))

for branch in "${branches[@]}"; do
    while true; do
        read -p "Delete branch '$branch'? [y/N] " answer
        case "$answer" in
            [yY]|[yY][eE][sS])
                sh -c "git $git_extra_args branch -d $branch"
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