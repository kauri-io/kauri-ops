#!/bin/sh

# This script will be executed after commit in placed in .git/hooks/post-commit

# Semantic Versioning 2.0.0 guideline
#
# Given a version number MAJOR.MINOR.PATCH, increment the:
# MAJOR version when you make incompatible API changes,
# MINOR version when you add functionality in a backwards-compatible manner, and
# PATCH version when you make backwards-compatible bug fixes.

echo "Starting the taging process based on commit message +semver: xxxxx"

#get highest tags across all branches, not just the current branch
VERSION=`git describe --tags $(git rev-list --tags --max-count=1)`

# split into array
VERSION_BITS=(${VERSION//./ })

echo "Latest version tag: $VERSION"

#get number parts and increase last one by 1
VNUM1=${VERSION_BITS[0]}
VNUM2=${VERSION_BITS[1]}
VNUM3=${VERSION_BITS[2]}
# VNUM3=$((VNUM3+1))

# Taken from gitversion
# major-version-bump-message: '\+semver:\s?(breaking|major)'
# minor-version-bump-message: '\+semver:\s?(feature|minor)'
# patch-version-bump-message: '\+semver:\s?(fix|patch)'
# get last commit message and extract the count for "semver: (major|minor|patch)"
COUNT_OF_COMMIT_MSG_HAVE_SEMVER_MAJOR=`git log -1 --pretty=%B | egrep -c '\+semver:\s?(breaking|major)'`
COUNT_OF_COMMIT_MSG_HAVE_SEMVER_MINOR=`git log -1 --pretty=%B | egrep -c '\+semver:\s?(feature|minor)'`
COUNT_OF_COMMIT_MSG_HAVE_SEMVER_PATCH=`git log -1 --pretty=%B | egrep -c '\+semver:\s?(fix|patch)'`

if [ $COUNT_OF_COMMIT_MSG_HAVE_SEMVER_MAJOR -gt 0 ]; then
    VNUM1=$((VNUM1+1))
fi
if [ $COUNT_OF_COMMIT_MSG_HAVE_SEMVER_MINOR -gt 0 ]; then
    VNUM2=$((VNUM2+1))
fi
if [ $COUNT_OF_COMMIT_MSG_HAVE_SEMVER_PATCH -gt 0 ]; then
    VNUM3=$((VNUM3+1))
fi

# count all commits for a branch
GIT_COMMIT_COUNT=`git rev-list --count HEAD`
echo "Commit count: $GIT_COMMIT_COUNT"
export BUILD_NUMBER=$GIT_COMMIT_COUNT

#create new tag
NEW_TAG="$VNUM1.$VNUM2.$VNUM3"

echo "Updating $VERSION to $NEW_TAG"

#only tag if commit message have version-bump-message as mentioned above
if [ $COUNT_OF_COMMIT_MSG_HAVE_SEMVER_MAJOR -gt 0 ] ||  [ $COUNT_OF_COMMIT_MSG_HAVE_SEMVER_MINOR -gt 0 ] || [ $COUNT_OF_COMMIT_MSG_HAVE_SEMVER_PATCH -gt 0 ]; then
    echo "Tagged with $NEW_TAG (Ignoring fatal:cannot describe - this means commit is untagged) "
    git tag "$NEW_TAG"
else
    echo "Already a tag on this commit"
fi
