#!/bin/bash

set -e
if [[ -z "$1" ]]; then
  ACTIVITY=$(platform activities --type environment.push --limit 1 --format=plain --columns=id --no-header $@)
else
  ACTIVITY=$1
fi
platform activity:log $ACTIVITY
