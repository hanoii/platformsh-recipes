#!/bin/bash

export PLATFORMSH_RECIPES_VERSION=6be82fe
export PLATFORM_APP_DIR=/var/www/html/tmp
export PLATFORMSH_RECIPES_INSTALLDIR=/var/www/html/tmp/.platformsh-recipes
export PLATFORM_CACHE_DIR=/var/www/html/tmp/cache
source /dev/stdin  <<< "$(cat installer.sh)" -f

platformsh_recipes_cr_get_cache_dir
platformsh_recipes_maintenance_503_check
