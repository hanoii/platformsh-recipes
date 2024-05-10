#!/bin/bash

export PLATFORMSH_RECIPES_VERSION=808de168ca52fe727106af30f67e3699fae8f2b9
export PLATFORM_APP_DIR=/var/www/html/tmp
source /dev/stdin  <<< "$(cat installer.sh)" -f

platformsh_recipes_cr_get_cache_dir
platformsh_recipes_maintenance_503_check
