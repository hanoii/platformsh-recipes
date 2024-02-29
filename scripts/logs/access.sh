#!/bin/bash
set -e
OPTIONS=`getopt -o '' -l raw,extra:,days:,ip::,ua::,uri::,path::,status:,404,not-404,all -- "$@"`
eval set -- "$OPTIONS"


time=now
date=$(php -r "print gmdate('\\\\\\[d/M/Y', strtotime('$time'));")
grep_date='| grep -a "'"$date"'"'

# $1 ip
# $2 date
# $3 Request HTTP method
# $4 Request URI path
# $5 Request URI query string
# $6 Request HTTP version
# $7 HTTP status
# $8 referrer
# $9 ua

perl_start='| perl -pe "s/(.*?) - .*\[([^:]*:[^:]*:[^:]*).*?\] \"(.*?) (.*?)(\?.*?)? (.*?)\" (\d+) \d+ (\".*?\") (\".*?\")/'
perl_show='[\$7] \$1 \"\$3 \$4\$5\" \$8 \$9'
perl_end='/"'

grep_before=''
grep_after=''
grep_extra=''
grep_extension=
while true ; do
  case "$1" in
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
          date=$(php -r "print gmdate('\\\\\\[d/M/Y', strtotime('$time'));")
          grep_date='| grep -a "'"$date"'"'
          shift 2 ;;
      esac ;;
    --ip)
      perl_show='\$1 \$9'
      case "$2" in
        "") shift 2 ;;
        *)
          perl_show='[\$7] \$3 \$4\$5'
          grep_before="| grep -a '$2'"
          shift 2 ;;
      esac ;;
    --ua)
      perl_show='\$1 \$9'
      case "$2" in
        "") shift 2 ;;
        *)
          grep_after="| grep -a -i '$2'"
          shift 2 ;;
      esac ;;
    --uri)
      perl_show='[\$7] \$4\$5'
      case "$2" in
        "") shift 2 ;;
        *)
          grep_after="| grep -a '$2'"
          shift 2 ;;
      esac ;;
    --path)
      perl_show='[\$7] \$4'
      case "$2" in
        "") shift 2 ;;
        *)
          grep_after="| grep -a '$2'"
          shift 2 ;;
      esac ;;
    --status)
      grep_after='| grep -a "\['$2'\] "' ; shift 2 ;;
    --all)
      grep_date='' ; shift ;;
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

cmd='cat /var/log/access.log '"$grep_date"' '"$grep_extra"' '"$grep_extension"' '"$grep_before"' '"$perl_start$perl_show$perl_end"' '"$grep_after"' | sort | uniq -c | sort -n'
awk='awk '"'"'{sum += $1; print} END {print "\033[1;35m\n>>", sum, "total <<\n\033[0m" > "/dev/stderr"}'"'"
>&2 printf "\033[0;36mRunning [ %s | %s ]...\033[0m\n" "$cmd" "$awk"
if [ -z "$PLATFORM_APPLICATION_NAME" ]; then
  platform ssh -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} "$cmd" | eval $awk
else
  eval $cmd | eval $awk
fi
