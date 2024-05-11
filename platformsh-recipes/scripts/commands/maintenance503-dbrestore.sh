#!/bin/bash
#ddev-generated
set -e -o pipefail

if [ -z $1 ]; then
  gum log --level fatal You need to pass on the relationship name of the database to restore
fi
relationship_name=$1

gum log --level info Restoring all databases to $relationship_name...
platform ssh "\
  MYSQL_PWD=\$(echo \$PLATFORM_RELATIONSHIPS | base64 -d | jq -r \".${relationship_name}[0].password\") \
  screen \
    -m -S dbrestore -d bash -c '\
      pv \$PLATFORM_APP_DIR/.deploy/dump.sql | \
      mysql \
      -u \$(echo \$PLATFORM_RELATIONSHIPS | base64 -d | jq -r \".${relationship_name}[0].username\") \
      -h \$(echo \$PLATFORM_RELATIONSHIPS | base64 -d | jq -r \".${relationship_name}[0].host\"); \
      exec bash'
  "
gum log --level warn The restore is running on a detached screen on the environment, if you want to check progress, you can ssh to it and run 'screen -r dbrestore'
