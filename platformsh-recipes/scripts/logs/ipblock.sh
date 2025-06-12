#!/bin/bash
#ddev-generated
set -e -o pipefail

if [[ -z "$PLATFORMSH_CLI_TOKEN" ]]; then
  >&2 echo -e "\033[0;31mError: PLATFORMSH_CLI_TOKEN not available!\033[0m"
  exit 1
fi

if [[ -z "$PLATFORMSH_RECIPES_IPBLOCK_BLACKLIST" ]]; then
  >&2 echo -e "\033[0;31mError: PLATFORMSH_RECIPES_IPBLOCK_BLACKLIST not available!\033[0m"
  exit 1
fi

if [[ -z "$PLATFORMSH_RECIPES_IPBLOCK_WHITELIST" ]]; then
  >&2 echo -e "\033[0;33mWarning: PLATFORMSH_RECIPES_IPBLOCK_WHITELIST not available, this could be fine.\033[0m"
fi

OPTIONS=`getopt -o '' -l ips-only,days:,ip:,all,no-block -- "$@"`
eval set -- "$OPTIONS"

iponly=
ip=
days=
httpaccess=1
noblock=0

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    --ip)
      httpaccess=
      ip=$2
      shift 2
      ;;
    --ips-only)
      httpaccess=
      iponly=1
      shift
      ;;
    --all)
      days="--all"
      shift
      ;;
    --no-block)
      httpaccess=
      noblock=1
      shift
      ;;
    --days)
      case "$2" in
        "") shift 2 ;;
        *)
          days="--days $2"
          shift 2 ;;
      esac ;;
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done

if [ -n "$httpaccess" ]; then
  httpaccess=$(platform httpaccess -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} 2>&1)
  # { grep deny || test $? = 1; } from https://stackoverflow.com/a/49627999
  blocked_ips=($(echo "$httpaccess" | { grep deny || test $? = 1; }  | perl -pe "s/.*?address: '?([^\s\/]*).*/\$1/" | xargs -I {} echo '{}' | xargs))
  blocked_already=$(echo "$httpaccess" | { grep deny || test $? = 1; }  | perl -pe "s/.*?address: ([^\s]*).*/\$1/" | xargs -I {} echo '--access deny:{}' | xargs)
fi

# The first grep is a whitelist, the second
cmd_extra="grep -Pi '${PLATFORMSH_RECIPES_IPBLOCK_BLACKLIST//\'/\'\"\'\"\'}'"
if [[ -n "$PLATFORMSH_RECIPES_IPBLOCK_WHITELIST" ]]; then
  cmd_extra="grep -vPi '${PLATFORMSH_RECIPES_IPBLOCK_WHITELIST//\'/\'\"\'\"\'}' | $cmd_extra"
fi

cmd_ip=--ip
if [ -n "$ip" ]; then
  cmd_ip="--ip=$ip --raw"
fi

cmd_str="ahoy platform log:access $days $cmd_ip --extra '${cmd_extra//\'/\'\"\'\"\'}' $@"
>&2 echo -e "\033[0;36mRunning [ $cmd_str ]...\033[0m"
ips=$(eval $cmd_str 2> /tmp/platformsh-recipes.ipblock.stderr)
>&2 echo $(</tmp/platformsh-recipes.ipblock.stderr)

cmd_str="ahoy platform log:php:rpm $days $cmd_ip --per-second --greater-than 50 --ips-only --all | awk '{ print \"1000000\", \$0 }'"
>&2 echo -e "\033[0;36mRunning [ $cmd_str ]...\033[0m"
ips2=$(eval $cmd_str 2> /tmp/platformsh-recipes.ipblock.stderr)
>&2 echo $(</tmp/platformsh-recipes.ipblock.stderr)

if [ -n "$ip" ]; then
  echo "$ips"
  exit
fi

if [ -n "$iponly" ]; then
  echo "$ips" | awk '{ if ($1 > '${PLATFORMSH_RECIPES_IPBLOCK_THRESHOLD-20}') print $1 "," $2 ",bad" }'
  echo "$ips2" | awk '{ if ($1 > '${PLATFORMSH_RECIPES_IPBLOCK_THRESHOLD-20}') print $1 "," $2 ",rate" }'
  exit
fi

OLDIFS=$IFS
IFS=$'\n'
ips_array=($ips $ips2)
IFS=$OLDIFS
block=""
echo ""

whitelist=
whitelist_filename=$PLATFORM_APP_DIR/.deploy/.platformsh-recipes/ipblock.whitelist
if [ -f "$whitelist_filename" ]; then
  whitelist=$(cat "$whitelist_filename" | grep -v -e "^#")
fi

for i in ${!ips_array[*]}; do
  ip_cnt=(${ips_array[$i]})
  if [ ${ip_cnt[0]} -gt ${PLATFORMSH_RECIPES_IPBLOCK_THRESHOLD-20} ]; then
    ip=${ip_cnt[1]//[[:space:]]/}
    if [[ ! "$block" =~ "$ip" ]]; then
      if [[ ! "${blocked_ips[@]}" =~ $ip ]]; then
        if [[ "${whitelist[@]}" =~ $ip ]]; then
          >&2 echo -e "\033[0;33m[ warn  ] Bad IP $ip found with ${ip_cnt[0]} hits, but it is whitelisted...\033[0m"
          continue
        fi
        >&2 echo -e "\033[0;33m[       ] Bad IP $ip found with ${ip_cnt[0]} hits, about to be blocked...\033[0m"
        if [[ "$ip" =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
          block="$block --access deny:$ip/32"
        else
          block="$block --access deny:$ip/128"
        fi
      else
        if [[ "${whitelist[@]}" =~ $ip ]]; then
          >&2 echo -e "\033[0;31m[ error ] Bad IP $ip found with ${ip_cnt[0]} hits was blocked, but it is now whitelisted, please remove.\033[0m"
        fi
        >&2 echo -e "\033[0;32m[ ok    ] Bad IP $ip found with ${ip_cnt[0]} hits, but already blocked...\033[0m"
      fi
    else
      >&2 echo -e "\033[0;32m[ ok    ] Bad IP $ip found with ${ip_cnt[0]} hits, but already blocked...\033[0m"
    fi
  fi
done

if [ $noblock -eq 0 -a -n "$block" ]; then
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
