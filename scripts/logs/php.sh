#!/bin/bash
set -e

OPTIONS=`getopt -o '' -l not404,404,ip::,uri::,path::,days:,all,extension::,extra: -- "$@"`
eval set -- "$OPTIONS"

time=now
date=$(php -r "print gmdate('^Y-m-d', strtotime('$time'));")
grep_date='| grep -a "'"$date"'"'

# $1  date
# $2  ip
# $3  HTTP Method
# $4  HTTP Status
# $10 HTTP Host
# $11 URI path
# $12 URI query string
perl_start='| perl -pe "s/(^\d*[^:]*:[^:]*.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*) (.*) ([^\?]*)(\?.*)?/'
perl_show='[\$4] \$2 \$10 \$3 \$11\$12'
perl_end='/"'
grep_before=
gre_after=
grep_extra=''
grep_extension=
# extract options and their arguments into variables.
while true ; do
  case "$1" in
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
      perl_show='\$11\$12'
      case "$2" in
        "") shift 2 ;;
        *)
          grep_after="| grep -a '$2'"
          perl_show='[\$4] \$2 \$10 \$3 \$11\$12'
          shift 2 ;;
        esac ;;
    --path)
      perl_show='\$11'
      case "$2" in
        "") shift 2 ;;
        *)
          grep_after="| grep -a '$2'"
          perl_show='[\$4] \$2 \$10 \$3 \$11'
          shift 2 ;;
        esac ;;
    --ip)
      perl_show='\$2'
      case "$2" in
        "") shift 2 ;;
        *)
          perl_show='[\$4] \$10 \$3 \$11\$12'
          grep_after="| grep -a '$2'"
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
      perl_show='[\$4] \$11'
      case "$2" in
        "")
          perl_show='\$11'
          grep_after='|  grep -a -P '"'"'\.[^/]*?$'"'"' | perl -pe '"'"'s/.*\.([^\?]*).*/$1/'"'"
          shift 2 ;;
        *)
          grep_after='| grep -a -P '"'"'\.'"$2"'$'"'"
          shift 2 ;;
      esac ;;
    --extra)
          grep_extra="$grep_extra | $2"
          shift 2 ;;
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done

cmd='cat /var/log/php.access.log '"$grep_date"' '"$grep_extra"' '"$grep_extension"' '"$grep_before"' '"$perl_start$perl_show$perl_end"' '"$grep_after"' | sort | uniq -c | sort -n'
awk='awk '"'"'{sum += $1; print} END {print "\033[1;35m\n>>", sum, "total <<\n\033[0m" > "/dev/stderr"}'"'"
>&2 printf "\033[0;36mRunning [ %s | %s ]...\033[0m\n" "$cmd" "$awk"
if [ -z "$PLATFORM_APPLICATION_NAME" ]; then
  platform ssh -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} "$cmd" | eval $awk
else
  eval $cmd | eval $awk
fi
