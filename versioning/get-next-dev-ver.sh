#!/bin/sh

#get highest tags across all branches, not just the current branch
VERSION=`git describe --tags $(git rev-list --tags --max-count=1)`

# split into array
VERSION_BITS=(${VERSION//./ })

VNUM1=${VERSION_BITS[0]}
VNUM2=${VERSION_BITS[1]}
VNUM3=${VERSION_BITS[2]}
VNUM3=$((VNUM3+1))

#create new version
NEW_DEV_VERSION="$VNUM1.$VNUM2.$VNUM3"
echo $NEW_DEV_VERSION
