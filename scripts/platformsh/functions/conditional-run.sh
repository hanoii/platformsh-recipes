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

platformsh_recipes_cr_cleanup() {
  local finddir="${PLATFORM_CACHE_DIR}/platformsh-recipes/cr"
  if [ -n "$1" ]; then
    finddir="$finddir/$1"
  fi
  find "$finddir" -mindepth 2 -type d -mtime +15 -exec rm -rf {} +
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
  find $1 -maxdepth 1 -name .platformsh-recipes.hash\.\* -not -name \*.bak -exec cp {} {}.bak \;
  cp .platformsh-recipes.hash.* $deploy_dir/.platformsh-recipes
}


### Presets

# Conditionally build and cache composer assets for drupal
platformsh_recipes_cr_preset_drupal_composer() {
  local hashfiles="composer.*"
  # Some directories normally present
  if [ -d patches/ ]; then
    hashfiles="$hashfiles patches/"
  fi
  if [ -d PATCHES/ ]; then
    hashfiles="$hashfiles PATCHES/"
  fi
  platformsh_recipes_cr_init "composer" \
    $(echo $PLATFORM_APPLICATION | base64 -d | jq '.type') \
    $hashfiles

  local cache_dir=$(platformsh_recipes_cr_get_cache_dir "composer")
  if platformsh_recipes_cr_should_run "composer"; then
    echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Composer install...\033[0m"
    if [[ $(composer --version 2> /dev/null) =~ ^Composer\ version\ 1 ]]; then
      composer global require composer/composer:^2
      export PATH=$(composer global config bin-dir --absolute --quiet):$PATH
    fi
    composer install --no-interaction --no-dev
    tar -czf ${cache_dir}/cache.tar.gz $(ls -d vendor/ web/core web/modules/contrib web/libraries web/themes/contrib web/profiles/contrib drush/Commands/contrib 2>/dev/null)
    platformsh_recipes_cr_success "composer"
    echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Composer cache stored!!\033[0m"
    ls -lha ${cache_dir}/cache.tar.gz
  else
    echo -e "\033[0;33m[$(date -u "+%Y-%m-%d %T.%3N")] [warning] Using composer dependencies from cache...\033[0m"
    tar -zxf ${cache_dir}/cache.tar.gz
    ls -lha ${cache_dir}/cache.tar.gz
    echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] Done using composer dependencies from cache!\033[0m"
  fi

  platformsh_recipes_cr_cleanup "composer"
}
