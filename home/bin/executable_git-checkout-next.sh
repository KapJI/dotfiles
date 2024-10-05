#!/bin/bash

git_extra_args=""
if [ ! -z "$GIT_DIR" ]; then
    git_extra_args="$git_extra_args --git-dir=$GIT_DIR"
fi
if [ ! -z "$GIT_WORK_TREE" ]; then
    git_extra_args="$git_extra_args --work-tree=$GIT_WORK_TREE"
fi

sh -c "git $git_extra_args log --reverse --pretty=%H master" | \
awk "/$(sh -c 'git $git_extra_args rev-parse HEAD')/{getline;print}" | \
xargs sh -c "git $git_extra_args checkout"
