#!/bin/bash
set -e -o pipefail

cmd=ahoy
if [ -z "$PLATFORM_APPLICATION_NAME" ]; then
  cmd="$cmd platform"
fi
blocked_ips=($(platform httpaccess -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} 2>&1 | grep deny | perl -pe "s/.*?address: ([^\s\/]*).*/\$1/" | xargs -I {} echo '{}' | xargs))
blocked_already=$(platform httpaccess -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} 2>&1 | grep deny | perl -pe "s/.*?address: ([^\s]*).*/\$1/" | xargs -I {} echo '--access deny:{}' | xargs)
cmd_str="$cmd log:access --ip --extra 'grep -Pi \"select[^a-zA-Z0-9_\-\/\s]|\.env|sysgmdate(\(|%28)|wp-content|wp-admin|go-http-client|(?<!/index)\.php|\.jsp HTTP|\.html HTTP\"' $@"
>&2 echo -e "\033[0;36mRunning '$cmd_str'...\033[0m"
ips=$(eval $cmd_str 2> /dev/null)
OLDIFS=$IFS
IFS=$'\n'
ips_array=($ips)
IFS=$OLDIFS
block=""
echo ""
for i in ${!ips_array[*]}; do
  ip_cnt=(${ips_array[$i]})
  if [ ${ip_cnt[0]} -gt 3 ]; then
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
    curl -s -o /dev/null https://apm.blackfire.io/api/v1/events --user "$BLACKFIRE_SERVER_ID:$BLACKFIRE_SERVER_TOKEN" -H "Content-type: application/json" -H "Accept: application/json" -d "{\"name\": \"Blocking ips: $block\"}"
    platform httpaccess -W $blocked_already $block
  fi
fi
