#!/bin/bash
# Platform.sh recipes installer

set -e -o pipefail

if [[ -z "$PLATFORMSH_RECIPES_VERSION" ]]; then
  >&2 echo -e "\033[0;31m[error] PLATFORMSH_RECIPES_VERSION not provided!\033[0m"
  exit 1
fi

if [[ -z "$PLATFORM_APP_DIR" ]]; then
  >&2 echo -e "\033[0;31m[error] This script is meant to be run on a Platform.sh environment!\033[0m"
  exit 1
fi

full=
while getopts "f" option; do
  case ${option} in
    f)
      full=1
      ;;
  esac
done

##
# Get the content of https://github.com/hanoii/platformsh-recipes.
###
PLATFORMSH_RECIPES_INSTALLDIR=${PLATFORMSH_RECIPES_INSTALLDIR-$PLATFORM_APP_DIR/.platformsh-recipes}
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing hanoii/platformsh-recipes...\033[0m"

if [ -n "$IS_DDEV_PROJECT" ] && [ -L $PLATFORMSH_RECIPES_INSTALLDIR ]; then
  rm $PLATFORMSH_RECIPES_INSTALLDIR
fi

mkdir -p $PLATFORMSH_RECIPES_INSTALLDIR
wget -qO- https://github.com/hanoii/platformsh-recipes/archive/${PLATFORMSH_RECIPES_VERSION}.tar.gz | tar -zxf - --strip-component=1 -C $PLATFORMSH_RECIPES_INSTALLDIR

if [ -n "$IS_DDEV_PROJECT" ]; then
  rm -fr $PLATFORMSH_RECIPES_INSTALLDIR
  ln -fs ../ $PLATFORMSH_RECIPES_INSTALLDIR
fi

echo "${PLATFORMSH_RECIPES_VERSION}" > $PLATFORMSH_RECIPES_INSTALLDIR/version
if [[ -n "$full" ]]; then
  # Install tools
  $PLATFORMSH_RECIPES_INSTALLDIR/platformsh-recipes/assets/platformsh/build.sh
  echo "export PLATFORMSH_RECIPES_INSTALLDIR=$PLATFORMSH_RECIPES_INSTALLDIR" >> $PLATFORM_APP_DIR/.environment
  # Using . instead of source so it's dash-compatible.
  echo ". $PLATFORMSH_RECIPES_INSTALLDIR/platformsh-recipes/assets/platformsh/.environment" >> $PLATFORM_APP_DIR/.environment
fi
echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] Done installing hanoii/platformsh-recipes!\n\033[0m"

_latest=$(curl -s "https://api.github.com/repos/hanoii/platformsh-recipes/commits/main" | jq -r '.sha')
if [[ "$PLATFORMSH_RECIPES_VERSION" != "$_latest" ]]; then
  >&2 echo -e "\033[0;33m[warning] You are not using the latest version: '${_latest}'.\033[0m"
fi

source $PLATFORMSH_RECIPES_INSTALLDIR/platformsh-recipes/assets/platformsh/functions.sh
