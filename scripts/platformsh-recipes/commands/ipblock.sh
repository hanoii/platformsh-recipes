#!/bin/bash
set -e -o pipefail

# The command sets all of the IP addresses path, this is a helper command so
# that one can add a new ip to the list, it will not do anything, only build the
# command for you to run it.

if [[ -z "$1" ]]; then
  echo -e "You need to provide an ip to block!"
  exit 1
fi

httpaccess=$(platform httpaccess -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} 2>&1)
# { grep deny || test $? = 1; } from https://stackoverflow.com/a/49627999
blocked_already=$(echo "$httpaccess" 2>&1 | { grep deny || test $? = 1; } | perl -pe "s/.*?address: ([^\s]*).*/\$1/" | xargs -I {} echo '--access deny:{}' | xargs)
block="--access deny:$1"

>&2 echo -e "\033[0;36m\nIf you want to add the ip to the currently blocked IPs, run the following...\n\033[0m"
>&2 echo -e "platform httpaccess -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} \\\\\n\t\t\\\\\n\t\t$blocked_already \\\\\n\t\t\\\\\n\t\t$block"
