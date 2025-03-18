#!/bin/bash
#ddev-generated
set -e -o pipefail

if [ -z $1 ]; then
  gum log --level fatal "You need to pass on the relationship name of the database to dump (the one on .platform.app.yaml)!"
fi
relationship_name=$1

gum log --level info Dumping all databases from $relationship_name on $(platform environment:info id)...
platform ssh "\
  MYSQL_PWD=\$(echo \$PLATFORM_RELATIONSHIPS | base64 -d | jq -r \".${relationship_name}[0].password\") \
  mysqldump \
    -u \$(echo \$PLATFORM_RELATIONSHIPS | base64 -d | jq -r \".${relationship_name}[0].username\") \
    -h \$(echo \$PLATFORM_RELATIONSHIPS | base64 -d | jq -r \".${relationship_name}[0].host\") \
    --protocol=tcp --all-databases --verbose > \$PLATFORM_APP_DIR/.deploy/dump-${relationship_name}.sql"
gum log --level warn "Remember to run 'platform backup -y'!"
