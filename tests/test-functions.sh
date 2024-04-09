#!/bin/bash

mkdir -p .cache/.deploy

PLATFORMSH_RECIPES_INSTALLDIR=.
source $PLATFORMSH_RECIPES_INSTALLDIR/scripts/platformsh/functions/conditional-run.sh
export PLATFORM_APP_DIR=.cache
export PLATFORM_CACHE_DIR=.cache

platformsh_recipes_cr_init "scripts" "" \
  scripts/ \
  tests/
if platformsh_recipes_cr_should_run "scripts"; then
  echo "Should run"
  dir=$(platformsh_recipes_cr_get_cache_dir "scripts")
  echo "test: $dir"

  # Do your stuff..

  platformsh_recipes_cr_success "scripts"
else
  dir=$(platformsh_recipes_cr_get_cache_dir "scripts")
  echo "test same: $dir"

  # Do your stuff

  echo "same"
fi


platformsh_recipes_cr_cleanup

platformsh_recipes_cr_deploy_store .cache/.deploy

# Errors
platformsh_recipes_cr_init "just one argument"
platformsh_recipes_cr_get_cache_dir
platformsh_recipes_cr_should_run
platformsh_recipes_cr_success
platformsh_recipes_cr_deploy_store
