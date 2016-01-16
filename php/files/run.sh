#!/usr/bin/env bash
set -e -x

# start php-fpm
/opt/source/php/sbin/php-fpm

# start nginx
/opt/source/nginx/sbin/nginx

tail -f /opt/source/logs/nginx/access.log
