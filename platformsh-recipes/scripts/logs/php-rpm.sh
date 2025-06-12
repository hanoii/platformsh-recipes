#!/bin/bash
#ddev-generated
set -e

OPTIONS=`getopt -o '' -l greater-than:,per-second,per-hour,hours:,days:,404,not-404,all,ips-only,ip::,extra: -- "$@"`
eval set -- "$OPTIONS"
grep_date=''
grep_extra=""

# $1  date
# $2  HTTP Method
# $3  HTTP Status
# $4  Milisconds
# $5  "ms"
# $6  RAM
# $7  "kb"
# $8  CPU%
# $9  URI path
# $10 URI query string
# $11 IP
# $12 HTTP Host
# #13 User-Agent
perl_start='| perl -pe "s/'
perl_date='(^\d*[^:]*:[^:]*).*?'
perl_other=' (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) ([^\s\?]+)(?:(\?[^\s]+))?(?:$| --v1-- (\S+) (\S+) (.*)|.*)/'
perl_show='\$1'
perl_end='/"'
pipe_extra=
per_hour=0
per_minute=1
per_second=0
# Default to looking back 3 hours
hours_back=3
hours_offset=0
grater_than=0

ips_only=0
all=0

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    --greater-than)
      grater_than=$2
      shift 2 ;;
    --per-second)
      per_hour=0
      per_minute=0
      per_second=1
      shift;;
    --per-hour)
      per_second=0
      per_minute=0
      per_hour=1
      shift;;
    --hours)
      hours_back=$2
      shift 2 ;;
    --days)
      hours_offset="$(($2*24))"
      days_offset=$2
      shift 2 ;;
    --ips-only)
      ips_only=1
      shift ;;
    --ip)
      perl_show='\$1 - \$11'
      case "$2" in
        "") shift 2 ;;
        *)
          grep_after="| grep -a '$2'"
          shift 2 ;;
      esac ;;
    --all)
      all=1
      shift ;;
    --404)
        grep_extra='| grep -a " 404 "' ; shift ;;
    --not-404)
        grep_extra='| grep -v -a " 404 "' ; shift ;;
    --extra)
          grep_extra="$grep_extra | $2"
          shift 2 ;;
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done

if [ $per_second -eq 1 ]; then
  if [ $all -eq 0 ]; then
    dates=()
    for ((i=0; i<hours_back; i++)); do
      dates+=("$(php -r "print gmdate('^Y-m-d\TH', strtotime('-$(($hours_offset + $i)) hours'));")")
    done
    grep_date='| grep -a -E "'"$(IFS="|"; echo "${dates[*]}")"'"'
  fi
  perl_date='(^\d*[^:]*:[^:]*:.*?)'
fi


if [ $per_minute -eq 1 ]; then
  if [ $all -eq 0 ]; then
    dates=()
    for ((i=0; i<hours_back; i++)); do
      dates+=("$(php -r "print gmdate('^Y-m-d\TH', strtotime('-$(($hours_offset + $i)) hours'));")")
    done
    grep_date='| grep -a -E "'"$(IFS="|"; echo "${dates[*]}")"'"'
  fi
fi

if [ $per_hour -eq 1 ]; then
  if [ $all -eq 0 ]; then
    date=$(php -r "print gmdate('^Y-m-d', strtotime('-$days_offset days'));")
    grep_date='| grep -a -e "'"$date"'"'
  fi
  perl_date='(^\d*[^:]*).*?'
fi

PHP_ACCESS_LOG_FILEPATH="/var/log/php.access.log"
if [ -n "$PLATFORMSH_RECIPES_DEV" ]; then
  PHP_ACCESS_LOG_FILEPATH="php.access.log"
fi
cmd='cat '"$PHP_ACCESS_LOG_FILEPATH"' '"$grep_date"' '"$grep_extra"' '"$pipe_extra"' '"$grep_before"' '"$perl_start$perl_date$perl_other$perl_show$perl_end"' '"$grep_after"' | sort | uniq -c'
gt=${GT_THRESHOLD:-$grater_than}
awk='awk -v gt="'$gt'" -v ips_only="'$ips_only'" '"'"'{if ($1 > gt) {sum += $1; print}} END {if (sum > 0 && ips_only != 1) print "\033[1;35m\n>>", sum, "total <<\n\033[0m" > "/dev/stderr"}'"'"
[ "$ips_only" = "1" ] && unique_ips_filter='| awk "{print \$4}" | sort | uniq' || unique_ips_filter=''
>&2 printf "\033[0;36mRunning [ %s | %s %s ]...\033[0m\n" "$cmd" "$awk" "$unique_ips_filter"
if [ -z "$PLATFORM_APPLICATION_NAME" -a -z "$PLATFORMSH_RECIPES_DEV" ]; then
  platform ssh -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} "$cmd" | eval $awk $unique_ips_filter
else
  eval $cmd | eval $awk $unique_ips_filter
fi
