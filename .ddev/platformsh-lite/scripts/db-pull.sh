#!/bin/bash
#ddev-generated
set -e -o pipefail

USAGE=$(cat << EOM
Usage: ${DDEV_PLATFORMSH_LITE_HELP_CMD-$0} [options]

  -h                This help text.
  -r                Reset default values as if run for the first time.
                    Allows to select different defaults.
  -e ENVIRONMENT    Use a different environment to download/import database.
  -n                Do not download, expect the dump to be already downloaded.
  -o                Import only, do not run post-import-db hooks.
EOM
)

function print_help() {
  gum style --border "rounded" --margin "1 2" --padding "1 2" "$@" "$USAGE"
}

env_file=/var/www/html/.ddev/platformsh-lite/.env.v3

while getopts ":rh" option; do
  case ${option} in
    h)
      print_help
      exit 0
      ;;
    r)
      [[ -f $env_file ]] && rm $env_file
      ;;
  esac
done
# Resetting OPTIND so that getopts can be used afterwards again
OPTIND=1

if [[ ! -f $env_file ]]; then
  print_help --foreground 8 --border-foreground 8

  gum log --level warn "First time running this command, querying platform for defaults..."

  # detect defaults
  if ! environment=$(gum spin --show-output --title="Detecting production environment" -- platform environments --type=production --pipe); then
    gum log --level error "Detecting platform production environment, you might want to check your PLATFORMSH_CLI_TOKEN on your config.local.yaml"
    exit 1
  fi
  if ! app=$(gum choose --select-if-one --header="Choose default app to pull database from..." $(gum spin --show-output --title="Querying apps..." -- platform apps -e $environment --format=plain --no-header --columns=name,type | tr '\t' '|') | sed 's/|.*//'); then
    gum log --level error --structured "Detecting platform applications" environment $environment
    exit 1
  fi
  relationships_yml=$(gum spin --show-output --title="Querying relationships..." -- platform environment:relationships -A $app -e $environment)
  relationships_cnt=$(echo "$relationships_yml" | yq '[ . | to_entries | sort_by(.key) | .[] | .value[0].key = .key | .value | select( .[].scheme == "mysql" or .[].scheme == "pgsql")] | length')
  relationships=$(echo "$relationships_yml" | yq '. | to_entries | sort_by(.key) | .[] | .value[0].key = .key | .value | select( .[].scheme == "mysql" or .[].scheme == "pgsql") | .[].key + "/" + .[].scheme')
  if ! relationship=$(gum filter --no-limit --select-if-one --header="Choose default relationship to pull database from..." $relationships); then
    gum log --level error --structured "Detecting database relationship" app $app environment $environment
    exit 1
  fi

  printf "%s\n" "DDEV_PLATFORMSH_LITE_PRODUCTION_BRANCH=$environment" "DDEV_PLATFORMSH_LITE_DEFAULT_APP=$app" "DDEV_PLATFORMSH_LITE_DEFAULT_RELATIONSHIP=$relationship" "DDEV_PLATFORMSH_LITE_DEFAULT_RELATIONSHIP_CNT=$relationships_cnt" > $env_file
else
  gum log --level debug --structured "Reading defaults from env file" file $env_file
  . $env_file
  environment=$DDEV_PLATFORMSH_LITE_PRODUCTION_BRANCH
  app=$DDEV_PLATFORMSH_LITE_DEFAULT_APP
  relationship=$DDEV_PLATFORMSH_LITE_DEFAULT_RELATIONSHIP
  relationships_cnt=$DDEV_PLATFORMSH_LITE_DEFAULT_RELATIONSHIP_CNT
fi

gum log --level info Production environment: $environment
gum log --level info Default App: $app
gum log --level info "Default relationship: $relationship (total relationships: $relationships_cnt)"

relationship_array=(${relationship//\// })
relationship_name=${relationship_array[0]}
relationship_scheme=${relationship_array[1]}

cmd_environment="-e $environment"
download=true
post_import=true

while getopts ":hne:or" option; do
  case ${option} in
    h)
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
    r)
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

filename=dump-${relationship_name}-$environment.sql.gz

gum log --level info "Creating $filename..."

if [[ "$download" == "true"  ]]; then
  if [ ! -z ${DDEV_PLATFORMSH_LITE_DRUSH_SQL_EXCLUDE+x} ]; then
    structure_tables=$DDEV_PLATFORMSH_LITE_DRUSH_SQL_EXCLUDE
  else
    if [[ "$DDEV_PROJECT_TYPE" == *"drupal"* ]] || [[ "$DDEV_BROOKSDIGITAL_PROJECT_TYPE" == *"drupal"* ]]; then
      if [[ "$relationship_scheme" == "mysql" ]]; then
        structure_tables=$(gum spin --show-output --title="Drupal project type, finding schema only tables..." -- platform -y db:sql -A $app -r ${relationship_name} $cmd_environment "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND (TABLE_NAME LIKE 'cache%' OR TABLE_NAME LIKE 'watchdog') ORDER BY TABLE_NAME" --raw | awk 'FNR > 1 {print}' | sed -z 's/\n/,/g' | sed 's/,$//')
        gum log --level debug "Schema only tables: $structure_tables"
      else
        gum log --level error "Database scheme ${relationship_scheme} not currently supported."
        exit 2
      fi
    fi
  fi


  cmd_structure_tables=
  cmd_exclude_tables=
  if [[ -n "$structure_tables" ]]; then
    IFS=',' read -r -a structure_tables_array <<< "$structure_tables"
    for t in "${structure_tables_array[@]}"; do
      cmd_structure_tables+="--table=$t "
      cmd_exclude_tables+="--exclude-table=$t "
    done
    temp_filename=$(mktemp)
    temp_filename_schema=$(mktemp)
    temp_filename_data=$(mktemp)
    gum spin --show-output --title="Dumping schema only tables..." -- platform -y db:dump -A $app -r ${relationship_name} $cmd_environment $cmd_structure_tables --schema-only --gzip -o > $temp_filename_schema
  fi
  gum spin --show-output --title="Dumping data tables..." -- platform -y db:dump -A $app -r ${relationship_name} $cmd_environment $cmd_exclude_tables --gzip -o > $temp_filename_data
  # attempt to remove /*!999999\- enable the sandbox mode */ if there
  # @see https://mariadb.org/mariadb-dump-file-compatibility-change/
  cat $temp_filename_schema | gunzip | tail +2 | gzip > $temp_filename
  cat $temp_filename_data | gunzip | tail +2 | gzip >> $temp_filename
  rm -f $filename
  mv $temp_filename $filename
else
  if [ ! -f $filename ]; then
    gum log --level error "Dump ${filename} not found. Please run it without -n."
    exit 3
  fi
fi

# Here we use the mysql database otherwise mysql alone will
# fail because 'db' will not be there once dropped.
mysql -uroot -proot -e 'DROP DATABASE IF EXISTS db' mysql
mysql -uroot -proot -e 'CREATE DATABASE db' mysql
pv $filename | gunzip | mysql

if [ -n "$post_import" ]; then
  # Run all post-import-db scripts
  /var/www/html/.ddev/pimp-my-shell/hooks/post-import-db.sh -A $app -r ${relationship_name} $cmd_environment
fi
