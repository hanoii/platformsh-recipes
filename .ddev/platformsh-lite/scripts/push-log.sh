#!/bin/bash
#ddev-generated
set -e -o pipefail

ACTIVITY=$(platform activities --type environment.push --limit 1 --format=plain --columns=id --no-header $@)
platform activity:log $ACTIVITY
