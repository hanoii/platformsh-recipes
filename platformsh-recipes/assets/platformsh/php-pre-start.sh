#!/usr/bin/env bash

# Custom php-fpm config for custom logging
# Idea from https://www.contextualcode.com/Blog/Extending-PHP-FPM-logs-on-Platform.sh
# I had to directly doing it here and using the .deploy mount as
# pm.max_children was not properly set on build hook (as the url above
# recommends)
# This is cleaner as well.

# This neeeds .platform.app.yaml modification:
#
# web:
#     commands:
#         pre_start: $PLATFORMSH_RECIPES_INSTALLDIR/platformsh-recipes/assets/platformsh/pre-start.sh
#         start: /usr/bin/start-php-app -y "$PLATFORM_APP_DIR/.deploy/php-fpm.conf"
#
#
# mounts:
#     '/.deploy':
#         source: local
#         source_path: 'deploy'

PHP_FPM_CUSTOM_CONF=${PHP_FPM_CUSTOM_CONF:-$PLATFORM_APP_DIR/.deploy/php-fpm.conf}
PHP_FPM_CONF=$(start-php-app -t 2>&1 | grep  -v -e "^$" | sort | uniq | perl -pe "s/.*?([^\s]*php-fpm.conf).*/\1/g")
cp "$PHP_FPM_CONF" "$PHP_FPM_CUSTOM_CONF"
PLATFORMSH_RECIPES_PHP_ACCESS_EXTRA=${PLATFORMSH_RECIPES_PHP_ACCESS_EXTRA:-"%{HTTP_X_CLIENT_IP}e %{HTTP_HOST}e %{HTTP_USER_AGENT}e"}
sed -i "s/access.format = \"\(.*\)\"/access.format = \"\\1 --v1-- $PLATFORMSH_RECIPES_PHP_ACCESS_EXTRA\"/" "$PHP_FPM_CUSTOM_CONF"
