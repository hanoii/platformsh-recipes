#!/bin/bash
#ddev-generated
set -e -o pipefail

gum log --level warn -- Excluding cron,backup,backup.delete by default, you can add them back by using --type=
ACTIVITY=$(platform activities --exclude-type=cron,backup,backup.delete --no-header "$@" 2>/dev/null | sed '1d;$d' | gum filter | awk '{print $2}')
if [ -n "$ACTIVITY" ]; then
  platform activity:log $ACTIVITY
else
  gum log --level error "There's no activity to log"
fi
