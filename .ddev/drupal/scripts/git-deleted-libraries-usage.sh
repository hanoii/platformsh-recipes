#!/bin/bash
#ddev-generated
set -e -o pipefail

if [[ "$DDEV_PROJECT_TYPE" == *"drupal"* ]] || [[ "$DDEV_BROOKSDIGITAL_PROJECT_TYPE" == *"drupal"* ]]; then
  set +o pipefail
  deleted_libraries=$(git status | grep -E 'web/libraries/.*?/' | grep deleted | perl -p -e 's|.*web/libraries/(.*?)/.*|web/libraries/\1|' | sort | uniq | xargs ls 2>&1 | grep cannot | perl -p -e "s|.*'web/(libraries/.*?)'.*|\1|" | xargs)
  set -o pipefail
  for i in $deleted_libraries; do
    echo -e "\033[1;36mLooking for $i on web/...\033[0m"
    if grep -R  "$i" web/; then
      :
    fi
    echo
  done
else
  echo -en "\033[1;31mNot drupal!\033[0m"
  exit 1
fi
