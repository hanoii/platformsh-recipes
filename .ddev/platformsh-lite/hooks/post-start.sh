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
else
  gum log --level=info Updating platformsh-cli...
  curl -fsSL https://raw.githubusercontent.com/platformsh/cli/main/installer.sh | bash | grep -E "Unpacking|newest" --color=never
fi

if [ ! -z "$PLATFORMSH_CLI_TOKEN" ]; then
  # Cert load
  platform ssh-cert:load -y

  if [[ ! -f .platform/local/project.yaml ]] || [[ ! -s .platform/local/project.yaml ]]; then
    if [[ "$PLATFORM_PROJECT" != "" ]]; then
      printf "* Setting remote project to $PLATFORM_PROJECT...\n"
      platform -y project:set-remote $PLATFORM_PROJECT
    else
      printf "✗ Platform.sh project was not set, needed for drush aliases. Please set PLATFORM_PROJECT env var.\n"
    fi
  fi

  # And create drush aliases, we need to have set remote
  if [[ "$DDEV_PROJECT_TYPE" == *"drupal"* ]] && [[ -f .platform/local/project.yaml ]]; then
    platform drush-aliases -r -g ${DDEV_PROJECT} -y
  fi
else
  gum log --level=warn PLATFORMSH_CLI_TOKEN is empty, the usual platform post-start commands have not run.
fi

# Special ssh config
# - It removes the Platform.sh' SSH key/certificate from the agent before everything else
# - It adds the Platform.sh' SSH key/certificate to the agent after
# - It forward agent keys through ssh for platform.sh domains
#
# This is to make sure that any new certificate gets added (if refreshed) and to
# avoid leaving lingering certificates in the ddev ssh-agent.

mkdir -p ~/.ssh/config.platformsh-lite.d
mkdir -p ~/.ssh/config.platformsh-lite.pre.d

# Add includes from config.platformsh-lite.pre.d/* on top of ~/.ssh/config
sed -i "1s@^@# Added by ddev-platformsh-lite add-on on $(date -u "+%Y-%m-%d %H:%m") \nInclude \"config.platformsh-lite.pre.d/*\"\n\n@" ~/.ssh/config
# Add includes from config.platformsh-lite.d/* to the end of ~/.ssh/config
echo -e "\n# Added by ddev-platformsh-lite add-on on $(date -u "+%Y-%m-%d %H:%m") \nInclude \"config.platformsh-lite.d/*\"" >> ~/.ssh/config

# Remove key/cert
cat <<'SSH_CONFIG' > ~/.ssh/config.platformsh-lite.pre.d/config
Match host "*.platform.sh" exec "ssh-add -L | grep -F 'platformsh-cli-temporary-cert' | ssh-add -d - > /dev/null 2>&1"
Host *
SSH_CONFIG

# Add key/cert to the agent
cat <<'SSH_CONFIG' > ~/.ssh/config.platformsh-lite.d/config
Match host "*.platform.sh" exec "ssh-add ~/.platformsh/.session/sess-cli-default/ssh/id_ed25519 > /dev/null 2>&1"
Host *
SSH_CONFIG

# Optionally set ForwardAgent=yes to all ssh connections to *.platform.sh hostnames
[ -n "$DDEV_PLATFORMSH_LITE_SSH_FORWARDAGENT" ] && cat <<'SSH_CONFIG' >> ~/.ssh/config.platformsh-lite.d/config || true
Host *.platform.sh
  ForwardAgent yes
Host *
SSH_CONFIG
