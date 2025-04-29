#!/bin/bash
#ddev-generated
set -e

OPTIONS=`getopt -o '' -l exact,raw,not404,404,ip::,uri::,path::,days:,all,extension::,host::,ua::,extra:,include-ip,include-host,include-ua,include-uri -- "$@"`
eval set -- "$OPTIONS"

time=now
date=$(php -r "print gmdate('^Y-m-d', strtotime('$time'));")
grep_date='| grep -a "'"$date"'"'

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
perl_start='| perl -pe "s/(^\d*[^:]*:[^:]*.*?) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) ([^\s\?]+)(?:(\?[^\s]+))?(?:$| --v1-- (\S+) (\S+) (.*)|.*)/'
perl_show='[\$3] \$2 \$9\$10'
perl_end='/"'
grep_before=
gre_after=
grep_extra=''
cmd_exact=''
grep_extension=
exact=
cmd_exact=
# extract options and their arguments into variables.
while true ; do
  case "$1" in
    --exact)
      exact=" || "
      cmd_exact="| perl -pe 's/ \|\| //g'"
      shift ;;
    --raw)
      perl_start=
      perl_show=
      perl_end=
      shift ;;
    --days)
      case "$2" in
        "") time=now ; shift 2 ;;
        *)
          time="-$2 days"
          date=$(php -r "print gmdate('^Y-m-d', strtotime('$time'));")
          grep_date='| grep -a -e "'"$date"'"'
          shift 2 ;;
      esac ;;
    --uri)
      case "$2" in
        "")
          perl_show='\$9\$10'
          shift 2 ;;
        *)
          perl_show=$exact'\$9\$10'$exact
          grep_after="| grep -a '$exact$2$exact'"
          shift 2 ;;
        esac ;;
    --path)
      case "$2" in
        "")
          perl_show='\$9'
          shift 2 ;;
        *)
          perl_show=$exact'\$9'$exact
          grep_after="| grep -a '$exact$2$exact'"
          shift 2 ;;
        esac ;;
    --ip)
      case "$2" in
        "")
          perl_show='\$11'
          shift 2 ;;
        *)
          grep_before="| grep -a '$2'"
          shift 2 ;;
        esac ;;
    --host)
      case "$2" in
        "")
          perl_show='\$12'
          shift 2 ;;
        *)
          grep_before="| grep -a '$2'"
          shift 2 ;;
        esac ;;
    --ua)
      case "$2" in
        "")
          perl_show='\$13'
          shift 2 ;;
        *)
          grep_before="| grep -a '$2'"
          shift 2 ;;
        esac ;;
    --404)
        grep_extra="| grep -a ' 404 '"
        shift ;;
    --not404)
        grep_extra="| grep -a -v ' 404 '"
        shift ;;
    --all)
      grep_date='' ; shift ;;
    --extension)
      case "$2" in
        "")
          perl_show='\$9'
          grep_after='|  grep -a -P '"'"'\.[^/]*?$'"'"' | perl -pe '"'"'s/.*\.([^\?]*).*/$1/'"'"
          shift 2 ;;
        *)
          grep_after='| grep -a -P '"'"'\.'"$2"'(?:$|\?)'"'"
          shift 2 ;;
      esac ;;
    --extra)
          grep_extra="$grep_extra | $2"
          shift 2 ;;
    --include-ip)
      perl_show="$perl_show -- \\\$11" ; shift ;;
    --include-host)
      perl_show="$perl_show -- \\\$12" ; shift ;;
    --include-ua)
      perl_show="$perl_show -- \\\$13" ; shift ;;
    --include-uri)
      perl_show="$perl_show -- \\\$9\\\$10" ; shift ;;
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done

PHP_ACCESS_LOG_FILEPATH="/var/log/php.access.log"
if [ -n "$PLATFORMSH_RECIPES_DEV" ]; then
  PHP_ACCESS_LOG_FILEPATH="php.access.log"
fi
cmd='cat '"$PHP_ACCESS_LOG_FILEPATH"' '"$grep_date"' '"$grep_extra"' '"$grep_extension"' '"$grep_before"' '"$perl_start$perl_show$perl_end"' '"$grep_after"' '"$cmd_exact"' | grep -v -e '^\$' | sort | uniq -c | sort -n'
awk='awk '"'"'{sum += $1; print} END {print "\033[1;35m\n>>", sum, "total <<\n\033[0m" > "/dev/stderr"}'"'"
>&2 printf "\033[0;36mRunning [ %s | %s ]...\033[0m\n" "$cmd" "$awk"
if [ -z "$PLATFORM_APPLICATION_NAME" -a -z "$PLATFORMSH_RECIPES_DEV" ]; then
  platform ssh -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} "$cmd" | eval $awk
else
  eval $cmd | eval $awk
fi
