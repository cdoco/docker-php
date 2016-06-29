# Pull base image
FROM daocloud.io/library/centos:latest
MAINTAINER Cdoco <ocdoco@gmail.com>

ENV PHP_VERSION 7.0.8

# Update source
RUN set -x \
    && yum update -y \
    && yum install wget gcc gcc-c++ make perl tar -y \
    && yum install libjpeg libpng libjpeg-devel libpng-devel libjpeg-turbo -y \
    && yum install freetype freetype-devel -y \
    && yum install libcurl-devel libxml2-devel -y \
    && yum install libjpeg-turbo-devel libXpm-devel -y \
    && yum install libXpm libicu-devel libmcrypt libmcrypt-devel -y \
    && yum install libxslt-devel libxslt -y \
    && yum install openssl openssl-devel bzip2-devel -y \
    && yum clean all \
    && mkdir -p /opt/data \
    && mkdir -p /opt/source \

# Install zlib
    && cd /opt/data \
    && wget http://jaist.dl.sourceforge.net/project/libpng/zlib/1.2.8/zlib-1.2.8.tar.gz \
    && tar zxvf zlib-1.2.8.tar.gz \
    && cd zlib-1.2.8 \
    && ./configure --static --prefix=/opt/source/libs/zlib \
    && make \
    && make install \

# Install openssl
    && cd /opt/data \
    && wget http://www.openssl.org/source/openssl-0.9.8zb.tar.gz \
    && tar zxvf openssl-0.9.8zb.tar.gz \
    && cd openssl-0.9.8zb \
    && ./config --prefix=/opt/source/libs/openssl -L/opt/source/libs/zlib/lib -I/opt/source/libs/zlib/include threads zlib enable-static-engine\
    && make \
    && make install \

# Install pcre
    && cd /opt/data \
    && wget http://jaist.dl.sourceforge.net/project/pcre/pcre/8.33/pcre-8.33.tar.gz \
    && tar zxvf pcre-8.33.tar.gz \
    && cd pcre-8.33 \
    && ./configure --prefix=/opt/source/libs/pcre \
    && make \
    && make install \

# Install nginx
    && cd /opt/data \
    && wget http://nginx.org/download/nginx-1.9.9.tar.gz \
    && tar zxvf nginx-1.9.9.tar.gz \
    && cd nginx-1.9.9 \
    && './configure' \
       '--prefix=/opt/source/nginx' \
       '--with-debug' \
       '--with-openssl=/opt/data/openssl-0.9.8zb' \
       '--with-zlib=/opt/data/zlib-1.2.8' \
       '--with-pcre=/opt/data/pcre-8.33' \
       '--with-http_stub_status_module' \
       '--with-http_gzip_static_module' \
    && make \
    && make install \

# Install libmcrypt
    && cd /opt/data \
    && wget ftp://mcrypt.hellug.gr/pub/crypto/mcrypt/libmcrypt/libmcrypt-2.5.6.tar.gz \
    && tar zxvf libmcrypt-2.5.6.tar.gz \
    && cd libmcrypt-2.5.6 \
    && ./configure \
    && make \
    && make install \

# Install php
    && cd /opt/data \
    && wget http://cn2.php.net/distributions/php-$PHP_VERSION.tar.gz \
    && tar zxvf php-$PHP_VERSION.tar.gz \
    && cd php-$PHP_VERSION \
    && './configure' \
       '--prefix=/opt/source/php/' \
       '--with-config-file-path=/opt/source/php/etc/' \
       '--with-config-file-scan-dir=/opt/source/php/conf.d/' \
       '--enable-fpm' \
       '--enable-cgi' \
       '--disable-phpdbg' \
       '--enable-mbstring' \
       '--enable-calendar' \
       '--with-xsl' \
       '--with-openssl' \
       '--enable-soap' \
       '--enable-zip' \
       '--enable-shmop' \
       '--enable-sockets' \
       '--with-gd' \
       '--with-jpeg-dir' \
       '--with-png-dir' \
       '--with-xpm-dir' \
       '--with-xmlrpc' \
       '--enable-pcntl' \
       '--enable-intl' \
       '--with-mcrypt' \
       '--enable-sysvsem' \
       '--enable-sysvshm' \
       '--enable-sysvmsg' \
       '--enable-opcache' \
       '--with-iconv' \
       '--with-bz2' \
       '--with-curl' \
       '--enable-mysqlnd' \
       '--with-mysqli=mysqlnd' \
       '--with-pdo-mysql=mysqlnd' \
       '--with-zlib' \
       '--with-gettext=' \
    && make \
    && make install \

# delete data dir
	&& yum remove -y gcc* make* \
    && rm -rf /opt/data \

# cp php conf
ADD files/php/php.ini /opt/source/php/etc/php.ini
ADD files/php/php-fpm.conf /opt/source/php/etc/php-fpm.conf
ADD files/php/www.conf /opt/source/php/etc/php-fpm.d/www.conf

# add nginx conf
ADD files/nginx/nginx.conf /opt/source/nginx/conf/nginx.conf
ADD files/nginx/default.conf /opt/source/nginx/conf/vhost/default.conf
RUN set -x \
    && mkdir /opt/source/logs \
    && mkdir /opt/source/logs/nginx \
    && touch /opt/source/logs/nginx/access.log

# add run.sh
ADD files/run.sh /opt/source/run.sh
RUN set -x \
    && chmod 755 /opt/source/run.sh

RUN set -x \
    && mkdir /opt/source/www \
    && echo "<?php phpinfo();?>" > /opt/source/www/index.php

# Start php-fpm And nginx
CMD ["/opt/source/run.sh"]

EXPOSE 80
EXPOSE 443
