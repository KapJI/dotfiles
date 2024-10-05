#!/bin/bash

## Usage
# $ git commit -am 'bad commit'
#
# $ git commit -am 'good commit'
#
## Stage changes to correct the bad commit
# $ git add .
#
## Fixup the bad commit. HEAD^ can be replaced by the SHA of the bad commit
# $ git fixup HEAD^

git_extra_args=""
if [ ! -z "$GIT_DIR" ]; then
    git_extra_args="$git_extra_args --git-dir=$GIT_DIR"
fi
if [ ! -z "$GIT_WORK_TREE" ]; then
    git_extra_args="$git_extra_args --work-tree=$GIT_WORK_TREE"
fi

TARGET=$(sh -c "git $git_extra_args rev-parse \"$1\"")
sh -c "git $git_extra_args commit --fixup=$TARGET ${@:2}" && EDITOR=true sh -c "git $git_extra_args rebase -i --autostash --autosquash $TARGET^"
