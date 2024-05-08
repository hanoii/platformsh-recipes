#!/bin/bash
#ddev-generated
set -e -o pipefail

USAGE=$(cat << EOM
Usage: ${DDEV_PLATFORMSH_LITE_HELP_CMD-$0} [options]

  -h                This help text.
  -c                Choose from the latest push activities.
  -l                The limit amount for the choose option, it defaults to 10 (platform cli default).
  -e ENVIRONMENT    Use a different environment to download/import database.
EOM
)

function print_help() {
  gum style --border "rounded" --margin "1 2" --padding "1 2" "$@" "$USAGE"
}

environment=
cmd_environment=
choose=
while getopts ":hce:l:" option; do
  case ${option} in
    h)
      print_help
      exit 0
      ;;
    l)
      cmd_limit="--limit=$OPTARG"
      ;;
    c)
      choose=1
      ;;
    e)
      environment=$OPTARG
      cmd_environment="-e $environment"
      ;;
  esac
done
# Resetting OPTIND so that getopts can be used afterwards again
OPTIND=1

if [[ $choose -eq 1 ]]; then
  IFS=$'\n' ACTIVITY=$(gum filter $(platform activities --type=environment.push --format=tsv --no-header $cmd_limit) | awk '{print $1}')
else
  PENDING=$({ platform activities $cmd_environment --type environment.push --all --state=pending --format=plain --columns=id --no-header 2> /dev/null || true; } | wc -l)
  state_flag=
  if [[ "$PENDING" -gt 0 ]]; then
    gum log --level warn "There are still $PENDING pending builds"
    state_flag="--state=in_progress"
  fi

  ACTIVITY=$(platform activities $cmd_environment --type environment.push --limit 1 $state_flag --format=plain --columns=id --no-header)
fi

if [ -n "$ACTIVITY" ]; then
  platform activity:log $ACTIVITY
else
  gum log --level error "There's no push in progress to log"
fi
