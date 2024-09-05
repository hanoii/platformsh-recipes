#!/usr/bin/env bash
#ddev-generated

if [ -z "$PLATFORMSH_CLI_TOKEN" ]; then
  gum log --level=error PLATFORMSH_CLI_TOKEN is empty, this command needs it.
  exit 1
fi
