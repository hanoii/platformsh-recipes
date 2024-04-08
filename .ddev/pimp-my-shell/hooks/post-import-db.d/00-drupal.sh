#ddev-generated
#!/bin/bash
set -e -o pipefail

gum log --level info "Running $0..."
if [[ "$DDEV_PROJECT_TYPE" == *"drupal"* ]]; then
  if ! $(drush > /dev/null 2>&1); then
    gum log --level error drush not found!
    exit 1
  fi

  drush cr -y
  drush updb -y
  drush cim -y

  /var/www/html/.ddev/pimp-my-shell/scripts/drush-uli.sh
else
  gum log --level debug "Not drupal"
fi
