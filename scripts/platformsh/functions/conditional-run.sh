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
  { echo "$extra"; tar --mtime='1970-01-01' -czf - "$@";} | sha1sum | cut -d ' ' -f 1 > $hash_filename
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
  find "${PLATFORM_CACHE_DIR}/platformsh-recipes/cr" -mindepth 2 -type d -mtime +15 -exec rm -rf {} +
}

platformsh_recipes_cr_deploy_store() {
  if [ "$#" -lt 1 ] || [ ! -d $1 ] || [ ! -w $1 ]; then
    >&2 echo -e "\033[0;31m[error/${FUNCNAME[0]}] You need to pass a writable destination directory.\033[0m"
    return 10
  fi

  find $1 -maxdepth 1 -name .platformsh-recipes.hash\.\* -not -name \*.bak -exec cp {} {}.bak \;
  cp .platformsh-recipes.hash.* $1
}
