#!/bin/bash
#ddev-generated
set -e -o pipefail

if ! ssh-add -l >/dev/null; then
  gum log --level fatal Please run \'ddev auth ssh\' from your host before running this command.
  exit 1
fi

USAGE=$(cat << EOM
Usage: ${DDEV_DRUPAL_HELP_CMD-$0} [options]

  -h                This help text.
  -a ALIAS          Required! The remote drush alias (likely ssh) from where the database will be dumped. i.e. @live
  -n                Do not download, expect the dump to be already downloaded.
  -f FILE           Alternatively, provide a gzip'ed dump to import. Implies -n.
  -o                Import only, do not run post-import-db hooks.
  -v                Add -vvvv to drush commands
EOM
)

function print_help() {
  gum style --border "rounded" --margin "1 2" --padding "1 2" "$@" "$USAGE"
}

download=true
file=
post_import=true
alias=
verbose=

while getopts ":hvnoa:f:" option; do
  case ${option} in
    v)
      verbose="-vvvv"
      ;;
    h)
      print_help
      exit 0
      ;;
    a)
      alias=$OPTARG
      ;;
    n)
      download=
      ;;
    f)
      download=
      # alias=false is only os that a validation below passes
      alias=false
      file=$OPTARG
      ;;
    o)
      post_import=
      ;;
    :)
      gum log --level fatal -- Option \'-${OPTARG}\' requires an argument.
      echo "$USAGE"
      exit 1
      ;;
    ?)
      gum log --level fatal -- Invalid option: -${OPTARG}.
      echo "$USAGE"
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [[ -z $alias ]]; then
  gum log --level fatal This script needs a drush alias of the remote to work. Pass it with \'-a ALIAS\'.
  echo "$USAGE"
  exit 1
fi

clean_alias_filename=$(echo -n "${alias}" | perl -pe 's/@//g and s/[^0-9a-zA-Z]/-/g')
sql_filename=dump-${clean_alias_filename}.sql
sql_filename_gz="${sql_filename}.gz"

if [[ -n $file ]]; then
  sql_filename_gz=$file
fi

if [[ "$download" == "true"  ]]; then
  gum log --level info -- Dumping remote database on ${alias}...
  gum log --level info -- A progress of an increasing sql dump file size should appear, if not there might be connection issues, try adding -v ...
  drush $verbose ${alias} ssh "rm -f /tmp/${sql_filename_gz}"
  rm -f /tmp/db-pull-drush.ret
  sh -c " \
    { \
      { \
        drush $verbose -n ${alias} sql-dump --gzip --result-file=/tmp/${sql_filename}; \
        ret=\$?; \
        echo \$ret > /tmp/db-pull-drush.ret; \
      } \
      | \
      { \
        while [ ! -f /tmp/db-pull-drush.ret ]; do \
          drush ${alias} ssh '[ -f /tmp/${sql_filename_gz} ] && du -hs /tmp/${sql_filename_gz} || true'; \
          sleep 2; \
          done; \
      }; \
      exit \$(cat /tmp/db-pull-drush.ret); \
    } \
    "
    gum log --level info Downloading remote database from ${alias} to ${sql_filename_gz}...
  drush $verbose rsync ${alias}:/tmp/${sql_filename_gz} . -y -- --delete
fi

if [[ ! -f ${sql_filename_gz} ]]; then
  gum log --level fatal -- ${sql_filename}.gz not found! Run \'${DDEV_DRUPAL_HELP_CMD-$0}\' it without \'-n\'
  exit 1
fi

mysql -uroot -proot -e 'DROP DATABASE IF EXISTS db' mysql
mysql -uroot -proot -e 'CREATE DATABASE db' mysql
gum log --level info Importing remote database...
pv ${sql_filename_gz} | gunzip | mysql db

if [ -n "$post_import" ]; then
  # Run all post-import-db scripts
  /var/www/html/.ddev/pimp-my-shell/hooks/post-import-db.sh
fi
