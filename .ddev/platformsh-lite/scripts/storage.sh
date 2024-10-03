#!/bin/bash
#ddev-generated
set -e -o pipefail

platform_storage=$(platform subscription:info storage)
platform_files=$(find . -name .platform.app.yaml)
platform_services=$(find .platform -name services.yaml)
grep -e "^\s*disk:" -r $platform_files $platform_services | \
  perl -p -e 's/([^0-9]*)([0-9]*)/\2 \1/' | \
  perl -p -e 's/:.*?disk://' | \
  awk '{sum += $1; print} END {print "\033[1;35m\n>>", sum, "bytes (" sum/1024 "gb) -", (sum/'$platform_storage')*100 "% allocated -", '$platform_storage'-sum " bytes (" ('$platform_storage'-sum)/1024 "gb)", "free <<\n\033[0m" > "/dev/stderr"}'
