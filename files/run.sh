#!/usr/bin/env bash
set -e -x

# start php-fpm
/data/server/php/sbin/php-fpm

# start nginx
/data/server/nginx/sbin/nginx -g "daemon off;"
