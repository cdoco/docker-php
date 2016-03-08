#!/bin/bash
# PHP 5.5 update scripts

if [ ! $1 ];then
	Ver=5.5.9
else
	Ver=$1
fi

Debugfile=20121212

echo "THANK YOU FOR USING UPDATE SCRIPT MADE BY AREFLY.COM"
echo "YOU ARE GOING TO UPDATE YOUR PHP TO ${Ver}"
echo "YOU CAN JUST HAVE A REST"
echo "IT MAY TAKE A LOT OF TIME"
echo
#read -p "PRESS ENTER IF YOU REALLY WANT TO UPDATE"
read -p "DO YOU REALLY WANT TO UPDATE? (Y/N)" yn
if [ "$yn" == "Y" ] || [ "$yn" == "y" ]; then
	echo "PHP IS NOW UPDATING!"
else
	exit
fi
echo
echo "-------------------------------------------------------------"
echo

###yum
yum install -y libmcrypt-devel libjpeg-devel libpng-devel freetype-devel curl-devel openssl-devel libxml2-devel zip unzip

###
if [ ! -f php-${Ver}.tar.gz ];then
	wget -c http://us1.php.net/distributions/php-${Ver}.tar.gz
fi
if [ ! -f iconv_ins.sh ];then
	wget -c http://down.wdlinux.cn/in/iconv_ins.sh
	sh iconv_ins.sh
fi

###
if [ -f /data/www/mysql/lib/libmysqlclient.so.18 ];then
	if [ -d /usr/lib64 ];then
		LIBNCU="/usr/lib64"
	else
		LIBNCU="/usr/lib"
	fi
	ln -sf /data/www/mysql/lib/libmysqlclient.so.18 $LIBNCU
fi

tar zxvf php-${Ver}.tar.gz
cd php-${Ver}
if [ -d /data/www/apache_php ];then
echo "START CONFIGURING PHP ON NGINX"
sleep 3
make clean
	./configure --prefix=/data/www/apache_php-${Ver} --with-config-file-path=/data/www/apache_php-${Ver}/etc --with-mysql=/data/www/mysql --with-iconv=/usr --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-mcrypt=/usr --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-ftp --enable-sockets --enable-zip --with-apxs2=/data/www/apache/bin/apxs --with-mysqli=/data/www/mysql/bin/mysql_config --with-pdo-mysql=/data/www/mysql --enable-opcache --enable-bcmath
[ $? != 0 ] && echo "NO! CONFIGURE ERROR! TRY AGAIN OR ASK IN THE BBS! :(" && exit
echo "START MAKE"
sleep 3
make
[ $? != 0 ] && echo "NO! MAKE ERROR! TRY AGAIN OR ASK IN THE BBS! :(" && exit
echo "START MAKE INSTALL"
sleep 3
make install
[ $? != 0 ] && echo "NO! MAKE INSTALL ERROR! TRY AGAIN OR ASK IN THE BBS! :(" && exit
cp php.ini-production /data/www/apache_php-${Ver}/etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /data/www/apache_php-${Ver}/etc/php.ini
rm -f /data/www/apache_php
ln -sf /data/www/apache_php-${Ver} /data/www/apache_php
if [ ! -d /data/www/apache_php-${Ver}/lib/php/extensions ];then
	mkdir -p /data/www/apache_php-${Ver}/lib/php/extensions/no-debug-zts-${Debugfile}
	ln -sf /data/www/apache_php-${Ver}/lib/php/extensions/no-debug-zts-${Debugfile} /data/www/apache_php-${Ver}/lib/php/extensions/no-debug-non-zts-${Debugfile}
fi
service httpd restart
fi

if [ -d /data/www/nginx_php ];then
echo "START CONFIGURING PHP ON APACHE"
sleep 3
make clean
	./configure --prefix=/data/www/nginx_php-${Ver} --with-config-file-path=/data/www/nginx_php-${Ver}/etc --with-mysql=/data/www/mysql --with-iconv=/usr --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-mcrypt=/usr --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-ftp --enable-sockets --enable-zip --enable-fpm --with-mysqli=/data/www/mysql/bin/mysql_config --with-pdo-mysql=/data/www/mysql
[ $? != 0 ] && echo "NO! CONFIGURE ERROR! TRY AGAIN OR ASK IN THE BBS! :(" && exit
echo "START MAKE"
sleep 3
make
[ $? != 0 ] && echo "NO! MAKE ERROR! TRY AGAIN OR ASK IN THE BBS! :(" && exit
echo "START MAKE INSTALL"
sleep 3
make install
[ $? != 0 ] && echo "NO! MAKE INSTALL ERROR! TRY AGAIN OR ASK IN THE BBS! :(" && exit
cp php.ini-production /data/www/nginx_php-${Ver}/etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /data/www/nginx_php-${Ver}/etc/php.ini
service php-fpm stop
rm -f /data/www/nginx_php
ln -sf /data/www/nginx_php-${Ver} /data/www/nginx_php
cp /data/www/nginx_php-${Ver}/etc/php-fpm.conf.default /data/www/nginx_php-${Ver}/etc/php-fpm.conf
sed -i 's/user = nobody/user = www/g' /data/www/nginx_php/etc/php-fpm.conf
sed -i 's/group = nobody/group = www/g' /data/www/nginx_php/etc/php-fpm.conf
sed -i 's/;pid =/pid =/g' /data/www/nginx_php/etc/php-fpm.conf
cp -f sapi/fpm/init.d.php-fpm /data/www/init.d/php-fpm
chmod 755 /data/www/init.d/php-fpm
if [ ! -d /data/www/nginx_php-${Ver}/lib/php/extensions ];then
	mkdir -p /data/www/nginx_php-${Ver}/lib/php/extensions/no-debug-zts-${Debugfile}
	ln -sf /data/www/nginx_php-${Ver}/lib/php/extensions/no-debug-zts-${Debugfile} /data/www/nginx_php-${Ver}/lib/php/extensions/no-debug-non-zts-${Debugfile}
fi
fi
cd ..
rm -rf php-${Ver}/
rm -rf php-${Ver}.tar.gz
rm -rf iconv_ins.sh
echo
echo "-------------------------------------------------------------"
echo "PHP UPDATE FINISH! :D"
