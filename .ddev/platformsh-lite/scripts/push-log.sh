#!/bin/bash
#ddev-generated
set -e -o pipefail

USAGE=$(cat << EOM
Usage: ${DDEV_PLATFORMSH_LITE_HELP_CMD-$0} [options]

  -h                This help text.
  -c                Choose from the latest push activities.
  -l                The limit amount for the choose option, it defaults to 10 (platform cli default).
  -e ENVIRONMENT    Use a different environment to get activity log from.
  -p PROJECT_ID     Use a specific platform project ID.
  -w                Wait for in_progress activities to complete.
EOM
)

function print_help() {
  gum style --border "rounded" --margin "1 2" --padding "1 2" "$@" "$USAGE"
}

environment=
cmd_environment=
project_id=
cmd_project=
choose=
wait_for_progress=
while getopts ":hce:l:p:w" option; do
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
    p)
      project_id=$OPTARG
      cmd_project="-p $project_id"
      ;;
    w)
      wait_for_progress=1
      ;;
  esac
done
# Resetting OPTIND so that getopts can be used afterwards again
OPTIND=1

# Wait for in_progress activities if requested
if [[ $wait_for_progress -eq 1 ]]; then
  echo "🔄 Waiting for an in_progress activity to start..."
  while true; do
    IN_PROGRESS_ACTIVITY=$(platform activities $cmd_project $cmd_environment --type=environment.push --state=in_progress --limit=1 --format=plain --columns=id --no-header 2>/dev/null || true)
    if [[ -n "$IN_PROGRESS_ACTIVITY" ]]; then
      echo "✅ Found in_progress activity: $IN_PROGRESS_ACTIVITY"
      ACTIVITY="$IN_PROGRESS_ACTIVITY"
      break
    else
      echo "⏳ No in_progress activities found, waiting..."
      sleep 5
    fi
  done
fi

# Only run the normal activity selection logic if we haven't already found one from waiting
if [[ -z "$ACTIVITY" ]]; then
  if [[ $choose -eq 1 ]]; then
    ACTIVITY=$(platform activities $cmd_project $cmd_environment --type=environment.push --format=tsv --no-header $cmd_limit | gum filter | awk '{print $1}')
  else
    PENDING=$({ platform activities $cmd_project $cmd_environment --type environment.push --all --state=pending --format=plain --columns=id --no-header 2> /dev/null || true; } | wc -l)
    state_flag=
    if [[ "$PENDING" -gt 0 ]]; then
      gum log --level warn "There are still $PENDING pending builds"
      state_flag="--state=in_progress"
    fi

    ACTIVITY=$(platform activities $cmd_project $cmd_environment --type environment.push --limit 1 $state_flag --format=plain --columns=id --no-header)
  fi
fi

if [ -n "$ACTIVITY" ]; then
  platform activity:log $cmd_project $ACTIVITY
else
  gum log --level error "There's no push in progress to log"
fi
