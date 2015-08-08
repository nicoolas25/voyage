#!/bin/bash

# This script requires you to have the following tree structure:
#
# - blog           git:(source)
# - blog-compiled  git:(gh-pages)
#
# This script is expected to be run inside the "blog" directory.
# The "blog" directory contains the jekyll files, plugins and directory
# since it point to the source branch of the repository.
# The "blog-compiled" directory contains the jekyll generated files that
# will be pushed to the "gh-pages" branch.

SOURCE=`pwd`
TARGET=$(dirname $SOURCE)/$(basename $SOURCE)-compiled

function assert_git_branch_name_is {
  local name=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
  local expected_name=$1

  if [ "$name" != "$expected_name" ] ; then
    echo "Expected the branch name: '$name' to be equal to '$expected_name'."
    exit 1
  fi
}

function assert_git_branch_is_clean {
  local update_count=$(git status --porcelain | wc -l)

  if [ "$update_count" -ne "0" ] ; then
    echo "Expected the current git branch to be clean."
    echo "You should commit your changes before publication."
    exit 1
  fi

  local push_actions_count=$(git push --dry-run 2>&1 | wc -l)

  if [ "$push_actions_count" -gt "1" ] ; then
    echo "Expected the current git branch to be synced with its remote."
    echo "You should push your changes before publication."
    exit 1
  fi
}

echo "Building the static website..."
assert_git_branch_name_is "source"
assert_git_branch_is_clean
last_commit=$(git log --pretty=%s -n 1)
jekyll build -d "$TARGET"

echo "Publishing the content by pushing it to github..."
cd "$TARGET"
assert_git_branch_name_is "gh-pages"
git add --all .
timestamp=$(date "+%Y-%m-%d %H:%M:%S")
git ci -m "$last_commit - published at $timestamp"
git push
