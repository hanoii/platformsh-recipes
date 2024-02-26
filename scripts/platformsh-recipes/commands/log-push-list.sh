#!/bin/bash

set -e
platform activities --type environment.push --limit 20 "$@"
