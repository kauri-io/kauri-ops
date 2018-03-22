#!/bin/sh

echo "Getting next dev version based on hihest tag"

#get highest tags across all branches, not just the current branch
VERSION=`git describe --tags $(git rev-list --tags --max-count=1)`

# split into array
VERSION_BITS=(${VERSION//./ })

echo "Latest version tag: $VERSION"

VNUM1=${VERSION_BITS[0]}
VNUM2=${VERSION_BITS[1]}
VNUM3=${VERSION_BITS[2]}
VNUM3=$((VNUM3+1))

#create new version
export NEW_DEV_VERSION="$VNUM1.$VNUM2.$VNUM3"
echo "Exported new version as NEW_DEV_VERSION=$NEW_DEV_VERSION"
