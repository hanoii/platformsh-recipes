#!/usr/bin/env bash
#ddev-generated

FILENAME=/tmp/platform-sh-lite-addon-post-start
if [ -f "$FILENAME" ] ; then
  echo "platformsh-lite add-on post start script has already been run!"
  rm "$FILENAME"
  exit
fi

touch $FILENAME

# Update to the latest version, only if using the legacy-cli
# ddev versions before v1.23.0
# https://github.com/platformsh/legacy-cli
if [[ $(platform --version) =~ "Platform.sh CLI 4".* ]]; then
  platform self:update -qy --no-major || true

  # Install shell integration to avoid prompt
  # SHELL=$SHELL because of https://github.com/platformsh/cli/issues/117
  SHELL=$SHELL platform self:install -qy || true
fi

# Cert load
([ ! -z "${PLATFORMSH_CLI_TOKEN:-}" ] && platform ssh-cert:load -y) || true

if [[ ! -d .platform/local ]]; then
  if [[ "$PLATFORM_PROJECT" != "" ]]; then
    printf "* Setting remote project to $PLATFORM_PROJECT...\n"
    platform -y project:set-remote $PLATFORM_PROJECT
  else
    printf "✗ Platform.sh project was not set, needed for drush aliases. Please set PLATFORM_PROJECT env var.\n"
  fi
fi

# And create drush aliases, we need to have set remote
if [[ "$DDEV_PROJECT_TYPE" == *"drupal"* ]] && [[ -d .platform/local ]]; then
  ([ ! -z "${PLATFORMSH_CLI_TOKEN:-}" ] && platform drush-aliases -r -g ${DDEV_PROJECT} -y) || true
fi
