#!/bin/bash
#ddev-generated
set -e

OPTIONS=`getopt -o '' -l uri:,not-404,404,days:,all,mem,include-ip,include-host,include-ua -- "$@"`
eval set -- "$OPTIONS"

time=now
date=$(php -r "print gmdate('^Y-m-d', strtotime('$time'));")
grep_date='| grep -a "'"$date"'"'
grep_extra=''

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
perl_start='| perl -pe "s/(^\d*[^:]*:[^:]*.*?) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (\/[^\s\?]+)(?:(\?[^\s]+))?(?:$| --v1-- (\S+) (\S+) (.*)|.*)/'
perl_show='\$4\$5 \$6\$7'
perl_other=' \$2 \$9\$10 -> [\$2] \$3'
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
      perl_show='\$6\$7 \$4\$5'
      shift ;;
    --all)
      grep_date='' ; shift ;;
    --include-ip)
      perl_other="$perl_other \\\$11" ; shift ;;
    --include-host)
      perl_other="$perl_other \\\$12" ; shift ;;
    --include-ua)
      perl_other="$perl_other \\\$13" ; shift ;;
    --all)
      grep_date='' ; shift ;;
    --all)
      grep_date='' ; shift ;;
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done

PHP_ACCESS_LOG_FILEPATH="/var/log/php.access.log"
if [ -n "$PLATFORMSH_RECIPES_DEV" ]; then
  PHP_ACCESS_LOG_FILEPATH="php.access.log"
fi
cmd='cat '"$PHP_ACCESS_LOG_FILEPATH"' '"$grep_date"' '"$grep_extra"' '"$pipe_extra"' '"$perl_start$perl_show$perl_other$perl_end"' | sort -n'
>&2 printf "\033[0;36mRunning [ %s ]...\033[0m\n" "$cmd"
if [ -z "$PLATFORM_APPLICATION_NAME" -a -z "$PLATFORMSH_RECIPES_DEV" ]; then
  platform ssh -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} "$cmd"
else
  eval $cmd
fi
