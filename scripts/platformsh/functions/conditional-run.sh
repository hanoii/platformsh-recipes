#!/bin/bash

platformsh_recipes_cr_get_cache_dir() {
  if [ "$#" -lt 1 ]; then
    >&2 echo -e "\033[0;31m[error/${FUNCNAME[0]}] You need to pass an ID.\033[0m"
    return 10
  fi
  local id=$1
  local hash_filename=".platformsh-recipes.hash.$id"
  local hash=$(cat $hash_filename)
  echo "${PLATFORM_CACHE_DIR}/platformsh-recipes/cr/${id}/${hash}"
}

platformsh_recipes_cr_init() {
  if [ "$#" -lt 3 ]; then
    >&2 echo -e "\033[0;31m[error/${FUNCNAME[0]}] You need to pass an ID, an extra string (or empty), and a list of tar extra parameters followed by a list of files and/or directories.\033[0m"
    return 10
  fi
  local id=$1
  local extra=$2
  local hash_filename=".platformsh-recipes.hash.$id"
  shift 2
  # gzip -n is so that gzip doesn't add timestamp, that's also the reason I am
  # not using `tar -zcf` instead.
  { echo "$extra"; tar --mtime='1970-01-01' -cf - "$@";} | gzip -n | sha1sum | cut -d ' ' -f 1 > $hash_filename
  local cache_dir=$(platformsh_recipes_cr_get_cache_dir $id)
  mkdir -p $cache_dir
  # This so that it resets the modification time as it's cleanup unnecessarilly
  touch $cache_dir
}

platformsh_recipes_cr_should_run() {
  if [ "$#" -lt 1 ]; then
    >&2 echo -e "\033[0;31m[error/${FUNCNAME[0]}] You need to pass an ID.\033[0m"
    return 10
  fi
  local id=$1
  local hash_filename=".platformsh-recipes.hash.$id"
  local cache_dir=$(platformsh_recipes_cr_get_cache_dir $id)
  [[ ! -f ${cache_dir}/${hash_filename} ]] || ! cmp -s "${cache_dir}/${hash_filename}" $hash_filename
}

platformsh_recipes_cr_success() {
  if [ "$#" -lt 1 ]; then
    >&2 echo -e "\033[0;31m[error/${FUNCNAME[0]}] You need to pass an ID.\033[0m"
    return 10
  fi
  local id=$1
  local hash_filename=".platformsh-recipes.hash.$id"
  local cache_dir=$(platformsh_recipes_cr_get_cache_dir $id)
  cp $hash_filename ${cache_dir}/${hash_filename}
}

platformsh_recipes_cr_cache_store() {
  if [ "$#" -lt 2 ]; then
    >&2 echo -e "\033[0;31m[error/${FUNCNAME[0]}] You need to pass an ID paths to archive, accepting other tar commands.\033[0m"
    return 10
  fi
  local id=$1
  shift
  local cache_dir=$(platformsh_recipes_cr_get_cache_dir $id)
  tar -czf ${cache_dir}/cache.tar.gz "$@"
  echo -e "\033[0;36m$id assets stored in cache!!\033[0m"
}

platformsh_recipes_cr_cache_restore() {
  if [ "$#" -lt 1 ]; then
    >&2 echo -e "\033[0;31m[error/${FUNCNAME[0]}] You need to pass an ID.\033[0m"
    return 10
  fi
  local id=$1
  local cache_dir=$(platformsh_recipes_cr_get_cache_dir $id)
  tar -zxf ${cache_dir}/cache.tar.gz
  echo -e "\033[0;33m[warning] Using $id assets from cache...\033[0m"
}


platformsh_recipes_cr_cache_cleanup() {
  local finddir="${PLATFORM_CACHE_DIR}/platformsh-recipes/cr"
  # Cleanup all caches older than 15 days
  find "$finddir" -mindepth 2 -type d -mtime +15 -exec rm -rf {} +
  # Also only kep the latest 5 caches of each ID
  echo -e "\033[0;35m"
  for dir in "$finddir"/*; do
    if [ -d "$dir" ]; then  # Check if it's a directory
      find "$dir" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -nr | awk 'FNR > 5 {print $2}' | xargs rm -rf
      du -hs --time $dir/* | awk -F'\t' '{print $2 "\t"  $3 "\t" $1}' | sort
      echo ""
    fi
  done
  du -hs --time $finddir | awk -F'\t' '{print "Cache total: " $1}'
  echo -e "\033[0m"
}

platformsh_recipes_cr_deploy_should_run() {
  if [ "$#" -lt 1 ]; then
    >&2 echo -e "\033[0;31m[error/${FUNCNAME[0]}] You need to pass an ID.\033[0m"
    return 10
  fi
  local id=$1
  local hash_filename=".platformsh-recipes.hash.$id"
  local deploy_dir=$PLATFORM_APP_DIR/.deploy
  [[ ! -f ${deploy_dir}/.platformsh-recipes/${hash_filename} ]] || ! cmp -s "${deploy_dir}/.platformsh-recipes/${hash_filename}" $hash_filename
}

platformsh_recipes_cr_deploy_store() {
  local deploy_dir=$PLATFORM_APP_DIR/.deploy
  if [ ! -d $deploy_dir ] || [ ! -w $deploy_dir ]; then
    >&2 echo -e "\033[0;31m[error/${FUNCNAME[0]}] $deploy_dir must be writeable, make sure it's a mount in your .platform.app.yaml.\033[0m"
    return 10
  fi
  mkdir -p $deploy_dir/.platformsh-recipes
  find $deploy_dir/.platformsh-recipes -maxdepth 1 -name .platformsh-recipes.hash\.\* -not -name \*.bak -exec cp {} {}.bak \;
  cp .platformsh-recipes.hash.* $deploy_dir/.platformsh-recipes
}


### Presets

# Conditionally build and cache composer assets for drupal
platformsh_recipes_cr_preset_drupal_composer() {
  local version="202404111902"
  local hashfiles="composer.*"
  # Some directories normally present
  if [ -d patches/ ]; then
    hashfiles="$hashfiles patches/"
  fi
  if [ -d PATCHES/ ]; then
    hashfiles="$hashfiles PATCHES/"
  fi
  # This file is included in the hash as it can be changed by
  # drupal/core-composer-scaffold
  if [ -f web/.gitignore ]; then
    hashfiles="$hashfiles web/.gitignore"
  fi
  # Also add root .gitignore just in case, it shouldn't change often
  if [ -f .gitignore ]; then
    hashfiles="$hashfiles .gitignore"
  fi
  platformsh_recipes_cr_init "composer" \
    "$({ echo $version; echo $PLATFORM_APPLICATION | base64 -d | jq '.type'; })" \
    $hashfiles "$@"

  if platformsh_recipes_cr_should_run "composer"; then
    echo -e "\033[0;36mComposer install...\033[0m"
    local date=$(date --iso-8601=ns)
    if [[ $(composer --version 2> /dev/null) =~ ^Composer\ version\ 1 ]]; then
      composer global require composer/composer:^2
      export PATH=$(composer global config bin-dir --absolute --quiet):$PATH
    fi
    composer install --no-interaction --no-dev
    local composer_dirs=$(ls -d vendor/ web/core web/modules/contrib web/libraries web/themes/contrib web/profiles/contrib drush/Commands/contrib 2>/dev/null)
    local composer_drupal_extra=$(find web/ -type f -newermt $date -not -path 'web/core*' -not -path 'web/modules/contrib*' -not -path 'web/libraries*' -not -path 'web/themes/contrib*' -not -path 'web/profiles/contrib*')
    platformsh_recipes_cr_cache_store "composer" $composer_dirs $composer_drupal_extra
    platformsh_recipes_cr_success "composer"
  else
    platformsh_recipes_cr_cache_restore "composer"
  fi
}

# Conditionally build and cache composer assets for drupal
platformsh_recipes_cr_deploy_preset_drupal() {
  local cr=0;
  local cim=0;
  local updb=0

  if platformsh_recipes_cr_deploy_should_run "config"; then
    cim=1
  fi

  if platformsh_recipes_cr_deploy_should_run "composer" || platformsh_recipes_cr_deploy_should_run "code"; then
    updb=1; cr=1
  fi

  if platformsh_recipes_cr_deploy_should_run "theme" || platformsh_recipes_cr_deploy_should_run "settings"; then
    cr=1
  fi

  if [[ $cr -eq 1 ]]; then
    echo -e "\033[0;34m[$(date -u "+%Y-%m-%d %T.%3N")] Clearing caches...\033[0m"
    drush -y cache-rebuild
    echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] [success] Caches cleared!\033[0m"
  else
    echo -e "\033[0;33m[$(date -u "+%Y-%m-%d %T.%3N")] [warning] Skipping cache clear, not needed!\033[0m"
  fi

  if [[ $updb -eq 1 ]]; then
    echo -e "\033[0;34m[$(date -u "+%Y-%m-%d %T.%3N")] Updating db...\033[0m"
    drush -y updatedb
    echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] [success] Db updated!\033[0m"
  else
    echo -e "\033[0;33m[$(date -u "+%Y-%m-%d %T.%3N")] [warning] Skipping db update, not needed!\033[0m"
  fi

  if [[ $cim -eq 1 ]]; then
    echo -e "\033[0;34m[$(date -u "+%Y-%m-%d %T.%3N")] Importing config...\033[0m"
    drush -y config-import
    echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] [success] Config imported!\033[0m"
  else
    echo -e "\033[0;33m[$(date -u "+%Y-%m-%d %T.%3N")] [warning] Skipping config import, not needed!\033[0m"
  fi
}
