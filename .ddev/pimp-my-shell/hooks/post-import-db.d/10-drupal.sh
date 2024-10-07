#ddev-generated
#!/bin/bash
set -e -o pipefail

if [[ "$DDEV_PROJECT_TYPE" == *"drupal"* ]]; then
  if [[ "$DDEV_PROJECT_TYPE" == "drupal6" ]] || [[ "$DDEV_PROJECT_TYPE" == "drupal7" ]]; then
    gum log --level warn "$DDEV_PROJECT_TYPE is not supported by tye default drupal import-db script provided by the platformsh-lite ddev addon."
    gum log --level warn "Please provide your own .ddev/pimp-my-shell/hooks/post-import-db.d script for what you need to do after 'db:pull'."
    exit 0
  fi

  if ! $(drush > /dev/null 2>&1); then
    gum log --level error "drush not found, if this is a fresh init/clone, maybe run 'composer install'"
    exit 1
  fi

  drush -y deploy

  /var/www/html/.ddev/drupal/scripts/drush-uli.sh
else
  gum log --level debug "Not drupal"
fi
