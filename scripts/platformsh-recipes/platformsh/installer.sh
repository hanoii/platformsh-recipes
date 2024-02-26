#!/bin/bash
# Platform.sh recipes installer

set -euo pipefail

full=
while getopts "f" option; do
  case ${opt} in
    f)
      full=1
      ;;
  esac
done

##
# Get the content of https://github.com/hanoii/platformsh-recipes.
###
echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing hanoii/platformsh-recipes...\033[0m"
mkdir -p .platformsh-recipes
wget -qO- https://github.com/hanoii/platformsh-recipes/archive/de73c72459a81a4bcb08554a9b7e5a53a9d48edc.tar.gz | tar -zxf - --strip-component=1 -C .platformsh-recipes
if [[ -n "$full" ]]; then
  # Install tools
  ./.platformsh-recipes/scripts/platformsh-recipes/platformsh/build.sh
  echo "source $PLATFORM_APP_DIR/scripts/platformsh-recipes/platformsh/.environment" >> $PLATFORM_APP_DIR/.environment
  echo "source $PLATFORM_APP_DIR/scripts/platformsh-recipes/platformsh/.bashrc" >> $PLATFORM_APP_DIR/.bashrc
fi
echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] Done installing hanoii/platformsh-recipes!\n\033[0m"
