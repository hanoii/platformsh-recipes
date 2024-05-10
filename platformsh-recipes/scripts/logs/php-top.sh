#!/bin/bash
set -e

OPTIONS=`getopt -o '' -l uri:,not-404,404,days:,all,mem -- "$@"`
eval set -- "$OPTIONS"

time=now
date=$(php -r "print gmdate('^Y-m-d', strtotime('$time'));")
grep_date='| grep -a "'"$date"'"'
grep_extra=''

perl_start='| perl -pe "s/(^\d*[^:]*:[^:]*.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*) (.*) (.*)/'
perl_show='\$5 \$6 \$7 \$8'
perl_other=' \$2 \$10 \$11 -> [\$3] \$4'
perl_end='/"'

pipe_extra=
# extract options and their arguments into variables.
while true ; do
  case "$1" in
    --uri)
      case "$2" in
        "") shift 2 ;;
        *)
          grep_extra="| grep -a '$2'"
          shift 2 ;;
        esac ;;
    --ip)
      case "$2" in
        "") shift 2 ;;
        *)
          grep_extra="$grep_extra | grep $2"
          shift 2 ;;
      esac ;;
    --days)
      case "$2" in
        "") time=now ; shift 2 ;;
        *)
          time="-$2 days"
          date=$(php -r "print gmdate('^Y-m-d', strtotime('$time'));")
          grep_date='| grep -a -e "'"$date"'"'
          shift 2 ;;
      esac ;;
    --404)
      grep_extra='| grep -a " 404 "' ; shift ;;
    --not-404)
      grep_extra='| grep -v -a " 404 "' ; shift ;;
    --mem)
      perl_show='\$7 \$8 \$5 \$6'
      shift ;;
    --all)
      grep_date='' ; shift ;;
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done

cmd='cat /var/log/php.access.log '"$grep_date"' '"$grep_extra"' '"$pipe_extra"' '"$perl_start$perl_show$perl_other$perl_end"' | sort -n'
>&2 printf "\033[0;36mRunning [ %s ]...\033[0m\n" "$cmd"
if [ -z "$PLATFORM_APPLICATION_NAME" ]; then
  platform ssh -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} "$cmd"
else
  eval $cmd
fi
