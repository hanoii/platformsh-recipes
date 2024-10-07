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
  -o                Import only, do not run post-import-db hooks.
EOM
)

function print_help() {
  gum style --border "rounded" --margin "1 2" --padding "1 2" "$@" "$USAGE"
}

download=true
post_import=true
alias=

while getopts ":hnoa:" option; do
  case ${option} in
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

sql_filename=dump-${DDEV_PROJECT}.sql

if [[ "$download" == "true"  ]]; then
  gum log --level info Dumping remote database on ${alias}...
  gum spin --title="Running drush sql-dump on the remote..." --show-output -- drush ${alias} sql-dump --gzip --result-file=/tmp/${sql_filename}
  gum log --level info Downloading remote database from ${alias}...
  drush rsync ${alias}:/tmp/${sql_filename}.gz . -y -- --delete
fi

if [[ ! -f ${sql_filename}.gz ]]; then
  gum log --level fatal -- ${sql_filename}.gz not found! Run \'${DDEV_DRUPAL_HELP_CMD-$0}\' it without \'-n\'
  exit 1
fi

mysql -uroot -proot -e 'DROP DATABASE IF EXISTS db' mysql
mysql -uroot -proot -e 'CREATE DATABASE db' mysql
gum log --level info Importing remote database...
pv dump-${DDEV_PROJECT}.sql.gz | gunzip | mysql db

if [ -n "$post_import" ]; then
  # Run all post-import-db scripts
  /var/www/html/.ddev/pimp-my-shell/hooks/post-import-db.sh
fi
