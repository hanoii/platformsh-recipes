#!/bin/bash
set -e -o pipefail

if [[ -z "$PLATFORMSH_RECIPES_IPBLOCK_BLACKLIST" ]]; then
  >&2 echo -e "\033[0;31mError: PLATFORMSH_RECIPES_IPBLOCK_BLACKLIST not provided!\033[0m"
  exit 1
fi

if [[ -z "$PLATFORMSH_RECIPES_IPBLOCK_WHITELIST" ]]; then
  >&2 echo -e "\033[0;33mWarning: no PLATFORMSH_RECIPES_IPBLOCK_WHITELIST provided!\033[0m"
fi

httpaccess=$(platform httpaccess -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} 2>&1)
# { grep deny || test $? = 1; } from https://stackoverflow.com/a/49627999
blocked_ips=($(echo "$httpaccess" | { grep deny || test $? = 1; }  | perl -pe "s/.*?address: ([^\s\/]*).*/\$1/" | xargs -I {} echo '{}' | xargs))
blocked_already=$(echo "$httpaccess" | { grep deny || test $? = 1; }  | perl -pe "s/.*?address: ([^\s]*).*/\$1/" | xargs -I {} echo '--access deny:{}' | xargs)
# The first grep is a whitelist, the second
cmd_extra="grep -Pi \"$PLATFORMSH_RECIPES_IPBLOCK_BLACKLIST\""
if [[ -n "$PLATFORMSH_RECIPES_IPBLOCK_WHITELIST" ]]; then
  cmd_extra="grep -vPi \"$PLATFORMSH_RECIPES_IPBLOCK_WHITELIST\" | grep -Pi \"select[^a-zA-Z0-9_\-\/\s]|\.env|sysgmdate(\(|%28)|wp-content|wp-admin|go-http-client|(?<!/index)\.php|\.jsp HTTP|\.html HTTP\""
fi
cmd_str="ahoy platform log:access --ip --extra '$cmd_extra' $@"
>&2 echo -e "\033[0;36mRunning '$cmd_str'...\033[0m"
ips=$(eval $cmd_str 2> /tmp/platformsh-recipes.ipblock.stderr)
>&2 echo $(</tmp/platformsh-recipes.ipblock.stderr)
OLDIFS=$IFS
IFS=$'\n'
ips_array=($ips)
IFS=$OLDIFS
block=""
echo ""
for i in ${!ips_array[*]}; do
  ip_cnt=(${ips_array[$i]})
  if [ ${ip_cnt[0]} -gt ${PLATFORMSH_RECIPES_IPBLOCK_THRESHOLD-20} ]; then
    ip=${ip_cnt[1]//[[:space:]]/}
    if [[ ! "${blocked_ips[@]}" =~ $ip ]]; then
      >&2 echo -e "\033[0;33m[       ] Bad IP $ip found with ${ip_cnt[0]} hits, about to be blocked...\033[0m"
      if [[ "$ip" =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        block="$block --access deny:$ip/32"
      else
        block="$block --access deny:$ip/128"
      fi
    else
      >&2 echo -e "\033[0;32m[ ok    ] Bad IP $ip found with ${ip_cnt[0]} hits, but already blocked...\033[0m"
    fi
  fi
done
if [ -n "$block" ]; then
  if [ -z "$PLATFORM_APPLICATION_NAME" ]; then
    >&2 echo -e "\n\nIf you want to block the ips, run the following...\n"
    >&2 echo -e "platform httpaccess -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} \\\\\n\t\t\\\\\n\t\t$blocked_already \\\\\n\t\t\\\\\n\t\t$block"
  else
    if [ -n "$BLACKFIRE_SERVER_ID" ] && [ -n "$BLACKFIRE_SERVER_TOKEN" ]; then
      curl -s -o /dev/null https://apm.blackfire.io/api/v1/events --user "$BLACKFIRE_SERVER_ID:$BLACKFIRE_SERVER_TOKEN" -H "Content-type: application/json" -H "Accept: application/json" -d "{\"name\": \"Blocking ips: $block\"}"
    fi
    platform httpaccess -W $blocked_already $block
  fi
fi
