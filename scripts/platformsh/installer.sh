#!/bin/bash
# Platform.sh recipes installer

if [[ -z "$PLATFORMSH_RECIPES_VERSION" ]]; then
  echo "Error: PLATFORMSH_RECIPES_VERSION not provided!"
  exit 1
fi

set -euo pipefail

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
mkdir -p $PLATFORMSH_RECIPES_INSTALLDIR
wget -qO- https://github.com/hanoii/platformsh-recipes/archive/${PLATFORMSH_RECIPES_VERSION}.tar.gz | tar -zxf - --strip-component=1 -C $PLATFORMSH_RECIPES_INSTALLDIR
echo "${PLATFORMSH_RECIPES_VERSION}" > $PLATFORMSH_RECIPES_INSTALLDIR/version
if [[ -n "$full" ]]; then
  # Install tools
  $PLATFORMSH_RECIPES_INSTALLDIR/scripts/platformsh/build.sh
  echo "export PLATFORMSH_RECIPES_INSTALLDIR=$PLATFORMSH_RECIPES_INSTALLDIR" >> $PLATFORM_APP_DIR/.environment
  echo "source $PLATFORMSH_RECIPES_INSTALLDIR/scripts/platformsh/.environment" >> $PLATFORM_APP_DIR/.environment
  echo "source $PLATFORMSH_RECIPES_INSTALLDIR/.platformsh-recipes/scripts/platformsh/.bashrc" >> $PLATFORM_APP_DIR/.bashrc
fi
echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] Done installing hanoii/platformsh-recipes!\n\033[0m"
