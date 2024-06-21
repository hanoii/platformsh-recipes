#!/bin/bash

cd /var/www/html
export PLATFORMSH_RECIPES_INSTALLDIR=$(pwd)
mkdir -p tmp-for-test

# bookworm
export VERSION_ID_TEST_OVERRIDE=12
export VERSION_CODENAME_TEST_OVERRIDE=bookworm
export PLATFORM_APP_DIR=/var/www/html/tmp-for-test/${VERSION_CODENAME_TEST_OVERRIDE}
export PLATFORM_CACHE_DIR=/var/www/html/tmp-for-test/${VERSION_CODENAME_TEST_OVERRIDE}/cache
source /dev/stdin  <<< "$(cat $PLATFORMSH_RECIPES_INSTALLDIR/platformsh-recipes/assets/platformsh/build.sh)"

# bullseye
export VERSION_ID_TEST_OVERRIDE=11
export VERSION_CODENAME_TEST_OVERRIDE=bullseye
export PLATFORM_APP_DIR=/var/www/html/tmp-for-test/${VERSION_CODENAME_TEST_OVERRIDE}
export PLATFORM_CACHE_DIR=/var/www/html/tmp-for-test/${VERSION_CODENAME_TEST_OVERRIDE}/cache
source /dev/stdin  <<< "$(cat $PLATFORMSH_RECIPES_INSTALLDIR/platformsh-recipes/assets/platformsh/build.sh)"

# buster
export VERSION_ID_TEST_OVERRIDE=10
export VERSION_CODENAME_TEST_OVERRIDE=buster
export PLATFORM_APP_DIR=/var/www/html/tmp-for-test/${VERSION_CODENAME_TEST_OVERRIDE}
export PLATFORM_CACHE_DIR=/var/www/html/tmp-for-test/${VERSION_CODENAME_TEST_OVERRIDE}/cache
source /dev/stdin  <<< "$(cat $PLATFORMSH_RECIPES_INSTALLDIR/platformsh-recipes/assets/platformsh/build.sh)"

# stretch
export VERSION_ID_TEST_OVERRIDE=9
export VERSION_CODENAME_TEST_OVERRIDE=stretch
export PLATFORM_APP_DIR=/var/www/html/tmp-for-test/${VERSION_CODENAME_TEST_OVERRIDE}
export PLATFORM_CACHE_DIR=/var/www/html/tmp-for-test/${VERSION_CODENAME_TEST_OVERRIDE}/cache
source /dev/stdin  <<< "$(cat $PLATFORMSH_RECIPES_INSTALLDIR/platformsh-recipes/assets/platformsh/build.sh)"
