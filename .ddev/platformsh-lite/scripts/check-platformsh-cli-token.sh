#!/usr/bin/env bash
#ddev-generated

ddev debug compose-config | grep -qE 'PLATFORMSH_CLI_TOKEN:'

if [ $? -ne 0 ]; then
  echo -e "\033[0;31m"
  echo -e "[error] PLATFORMSH_CLI_TOKEN is necessary to start this project, please create a '.ddev/config.local.yaml' file with the following:"
  echo ""
  echo "--------------------------------------------------------------------------------"
  echo "web_environment:"
  echo "  - PLATFORMSH_CLI_TOKEN=<YOUR_TOKEN>"
  echo "--------------------------------------------------------------------------------"
  echo ""
  echo "@see https://docs.platform.sh/administration/cli/api-tokens.html"
  echo ""
  echo -en "\033[0m"
  echo -en "\033[0;35m"
  echo -e "[info] If you don't have a token, you can still add it but leave it empty 'PLATFORMSH_CLI_TOKEN=' for ddev to start, although some commands and scripts will not work."
  echo -e "\033[0m"
  exit 1
fi
