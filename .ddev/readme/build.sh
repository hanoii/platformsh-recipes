#!/bin/bash
#ddev-generated
set -e -o pipefail

prettier /var/www/html/README.md --cache-location /var/www/html/.ddev/readme/.cache/prettier --write --config=/var/www/html/.ddev/readme/.prettierrc
markdown-toc -i /var/www/html/README.md
