#!/bin/sh

# set this to your active development branch
develop_branch="development"
current_branch="$(git rev-parse --abbrev-ref HEAD)"

# only check commit messages on main development branch
[ "$current_branch" != "$develop_branch" ] && exit 0

# regex to validate in commit msg
commit_regex='(wap-[0-9]+)()'
error_msg="Aborting commit. Your commit message is missing either a JIRA Issue ('FLOW-1111') or a semver commit type 'breaking','major','feature','minor','fix','patch'"

if ! grep -iqE "$commit_regex" "$1"; then
    echo "$error_msg" >&2
    exit 1
fi
