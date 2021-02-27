#!/bin/bash


#
# Pre-checks
#

[ "$#" == "1" ] || {
        echo "Please give the module name or path as single argument. Aborting..."
        exit 1
}

MODULE="${1}"
echo "Working on git submodule ${MODULE}"

[ -d "${PWD}/${MODULE}" ] || {
        echo "Directory ${MODULE} does not exist. Aborting..."
        exit 2
}

#
# Check if either a 'meta/main.yml' file (for ansible roles) or a 'README.md' file (for terraform modules) is existing
# Abort if neither exists.
#
{ 
        [ -e "${PWD}/${MODULE}/meta/main.yml" ] || [ -e "${PWD}/${MODULE}/README.md" ]
} || {
        echo "git submodule ${MODULE} is not fully initalized and checked out."
        echo "Run 'git submodule init ${MODULE} && git submodule update ${MODULE}'"
        exit 2
}

#
# Ready for take off...
#

pushd "${PWD}/${MODULE}" > /dev/null || exit 11

if LANG=C git status | grep -q "nothing to commit, working tree clean"
then
        echo "Working directory is clean, continuing..."
else
        echo "Working directory is dirty, aborting..."
        git status
        exit 12
fi

( git checkout main || git checkout main ) || exit 13

git pull || exit 15

HASH_OF_LAST_COMMIT="$(git rev-parse --short HEAD)"
MESSAGE_OF_LAST_COMMIT="$(git log -1 --pretty=%B)"

[ -z "${HASH_OF_LAST_COMMIT}" ] && {
        echo "Variable HASH_OF_LAST_COMMIT is empty, aborting..."
        exit 16
}

[ -z "${MESSAGE_OF_LAST_COMMIT}" ] && {
        echo "Variable MESSAGE_OF_LAST_COMMIT  is empty, aborting..."
        exit 17
}

git checkout "${HASH_OF_LAST_COMMIT}" || exit 18

popd > /dev/null || exit 19

#
# Back in the parent repository
#

git add "${MODULE}" || exit 21

git commit -m "UPDATE git submodule ${MODULE} to commit ${HASH_OF_LAST_COMMIT}: ${MESSAGE_OF_LAST_COMMIT}" || exit 23

exit 0
