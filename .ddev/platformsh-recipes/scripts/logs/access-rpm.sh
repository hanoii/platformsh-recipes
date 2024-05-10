#!/bin/bash
#ddev-generated
set -e

OPTIONS=`getopt -o '' -l per-hour,hours:,ua::,date:,days:,404,not-404,allday,ip::,extra: -- "$@"`
eval set -- "$OPTIONS"

time=now
date=$(php -r "print gmdate('\\\\\\[d/M/Y:H', strtotime('$time'));")
grep_date='| grep -a "'"$date"'"'
grep_extra=""
perl_start='| perl -pe "s/(.*?) - .*'
perl_date='\[([^:]*:[^:]*:[^:]*).*?\]'
perl_other=' (\".*?\") (\d+) \d+ (\".*?\") (\".*?\")/'
perl_show='\$2'
perl_end='/"'
pipe_extra=
# extract options and their arguments into variables.
while true ; do
  case "$1" in
    --per-hour)
      date=$(php -r "print gmdate('\\\\\\[d/M/Y', strtotime('$time'));")
      grep_date='| grep -a "'"$date"'"'
      perl_date='\[([^:]*:[^:]*).*?\]'
      per_hour=1
      shift;;
    --hours)
      case "$2" in
        "") time=now ; shift 2 ;;
        *)
          time="-$2 hours"
          echo $time
          date=$(php -r "print gmdate('\\\\\\[d/M/Y:H', strtotime('$time'));")
          grep_date='| grep -a "'"$date"'"'
          shift 2 ;;
      esac ;;
    --ua)
      perl_show='\$2 - \$6'
      case "$2" in
        "") shift 2 ;;
        *)
          grep_after="| grep -a -i '$2'"
          shift 2 ;;
      esac ;;
    --show-ua)
      perl_show=$perl_show' \$6'
      shift;;
    --days)
      if [[ -z $per_hour && -z $allday ]]; then
        echo "--days only can be used after --per-hour or --allday" ; exit 1
      fi
      case "$2" in
        "") time=now ; shift 2 ;;
        *)
          time="-$2 days"
          date=$(php -r "print gmdate('\\\\\\[d/M/Y', strtotime('$time'));")
          grep_date='| grep -a "'"$date"'"'
          shift 2 ;;
      esac ;;
    --ip)
      perl_show='\$2 - \$1'
      case "$2" in
        "") shift 2 ;;
        *)
          grep_after="| grep -a '$2'"
          shift 2 ;;
      esac ;;
    --allday)
      allday=1
      date=$(php -r "print gmdate('\\\\\\[d/M/Y', strtotime('$time'));")
      grep_date='| grep -a "'"$date"'"'
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

cmd='cat /var/log/access.log '"$grep_date"' '"$grep_extra"' '"$pipe_extra"' '"$grep_before"' '"$perl_start$perl_date$perl_other$perl_show$perl_end"' '"$grep_after"' | sort | uniq -c'
awk='awk '"'"'{sum += $1; print} END {print "\033[1;35m\n>>", sum, "total <<\n\033[0m" > "/dev/stderr"}'"'"
>&2 printf "\033[0;36mRunning [ %s | %s ]...\033[0m\n" "$cmd" "$awk"
if [ -z "$PLATFORM_APPLICATION_NAME" ]; then
  platform ssh -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} "$cmd" | eval $awk
else
  eval $cmd | eval $awk
fi
