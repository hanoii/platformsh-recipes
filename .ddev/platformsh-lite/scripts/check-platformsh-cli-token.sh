#!/usr/bin/env bash
#ddev-generated

ddev debug compose-config | grep -qE 'PLATFORMSH_CLI_TOKEN: .{3,}'

if [ $? -ne 0 ]; then
  echo ""
  echo "PLATFORMSH_CLI_TOKEN is necessary to start this project, please create a '.ddev/config.local.yaml' file with the following:"
  echo ""
  echo "--------------------------------------------------------------------------------"
  echo "web_environment:"
  echo "  - PLATFORMSH_CLI_TOKEN=<YOUR_TOKEN>"
  echo "--------------------------------------------------------------------------------"
  echo ""
  echo "@see https://docs.platform.sh/administration/cli/api-tokens.html"
  echo ""
  exit 1
fi
