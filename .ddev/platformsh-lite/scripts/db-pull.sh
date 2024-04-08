#!/bin/bash
#ddev-generated
set -e -o pipefail

USAGE=$(cat << EOM

Usage: ${DDEV_PLATFORMSH_LITE_HELP_CMD-$0} [options]

  -h                This help text
  -e ENVIRONMENT    Use a different environment to download/import database
  -n                Do not download, expect the dump to be already downloaded.
  -o                Import only, do not run post-import-db hooks
EOM
)

env_file=/var/www/html/.ddev/platformsh-lite/.env

if [[ ! -f $env_file ]]; then
  gum log --level warn "First time running this command, querying platform for defaults..."

  # detect defaults
  if ! environment=$(gum spin --show-output --title="Detecting production environment" -- platform environments --type=production --pipe); then
    gum log --level error "Detecting platform production environment"
    exit 1
  fi
  if ! app=$(gum choose --select-if-one --header="Choose default app to pull database from..." $(gum spin --show-output --title="Querying apps..." -- platform apps -e $environment --format=plain --no-header --columns=name,type | tr '\t' '|') | sed 's/|.*//'); then
    gum log --level error --structured "Detecting platform applications" environment $environment
    exit 1
  fi
  if ! relationship=$(gum choose --select-if-one --header="Choose default relationship to pull database from..." $(gum spin --show-output --title="Querying relationships..." -- platform environment:relationships -A $app -e $environment | yq '. | to_entries | sort_by(.key) | .[] | .value[0].key = .key | .value | select( .[].scheme == "mysql" or .[].scheme == "pgsql") | .[].key')); then
    gum log --level error --structured "Detecting database relationship" app $app environment $environment
    exit 1
  fi

  printf "%s\n" "DDEV_PLATFORMSH_LITE_PRODUCTION_BRANCH=$environment" "DDEV_PLATFORMSH_LITE_DEFAULT_APP=$app" "DDEV_PLATFORMSH_LITE_DEFAULT_RELATIONSHIP=$relationship" > $env_file
else
  gum log --level debug --structured "Reading defaults from env file" file $env_file
  . $env_file
  environment=$DDEV_PLATFORMSH_LITE_PRODUCTION_BRANCH
  app=$DDEV_PLATFORMSH_LITE_DEFAULT_APP
  relationship=$DDEV_PLATFORMSH_LITE_DEFAULT_RELATIONSHIP
fi

gum log --level info Production environment: $environment
gum log --level info Default App: $app
gum log --level info Default relationship: $relationship

cmd_environment="-e $environment"
download=true
post_import=true
while getopts ":hne:o" option; do
  case ${option} in
    h)
      echo "$USAGE"
      exit 0
      ;;
    n)
      download=
      ;;
    e)
      environment=$OPTARG
      cmd_environment="-e $environment"
      ;;
    o)
      post_import=
      ;;
    :)
      echo -e "\033[1;31m[error] -${OPTARG} requires an argument.\033[0m"
      echo "$USAGE"
      exit 1
      ;;
    ?)
      echo -e "\033[1;31m[error] Invalid option: -${OPTARG}.\033[0m"
      echo "$USAGE"
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

filename=dump-$environment.sql.gz

if [[ "$download" == "true"  ]]; then
  echo "Fetching database to $filename..."
  if [[ "$DDEV_PROJECT_TYPE" == *"drupal"* ]] || [[ "$DDEV_BROOKSDIGITAL_PROJECT_TYPE" == *"drupal"* ]]; then
    platform -y drush -A $app $cmd_environment -- sql-dump --gzip --structure-tables-list=${DDEV_PLATFORMSH_LITE_DRUSH_SQL_EXCLUDE-cache*,watchdog,search*} --gzip > $filename
  else
    platform -y db:dump -A $app -r $relationship $cmd_environment --gzip -f $filename
  fi
fi

# Here we use the mysql database otherwise mysql alone will
# fail because 'db' will not be there once dropped.
mysql -uroot -proot -e 'DROP DATABASE IF EXISTS db' mysql
mysql -uroot -proot -e 'CREATE DATABASE db' mysql
pv $filename | gunzip | mysql

if [ -n "$post_import" ]; then
  # Run all post-import-db scripts
  /var/www/html/.ddev/pimp-my-shell/hooks/post-import-db.sh
fi
