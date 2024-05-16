#!/bin/bash

export PLATFORMSH_RECIPES_VERSION=6be82fe
export PLATFORM_APP_DIR=/var/www/html/tmp
export PLATFORMSH_RECIPES_INSTALLDIR=/var/www/html/tmp/.platformsh-recipes
source /dev/stdin  <<< "$(cat installer.sh)" -f

platformsh_recipes_cr_get_cache_dir
platformsh_recipes_maintenance_503_check
