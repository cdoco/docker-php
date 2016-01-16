# Pull base image
FROM daocloud.io/library/centos:latest
MAINTAINER Cdoco <ocdoco@gmail.com>

# Update source
RUN set -x \
    && yum update -y \
    && yum install wget gcc gcc-c++ make tar perl m4 cmake perl-Module-Install -y \
    && yum clean all \
    && mkdir /opt/data \
    && mkdir /opt/source

# Install bison
RUN set -x \
    && cd /opt/data \
    && wget http://ftp.gnu.org/gnu/bison/bison-2.7.tar.gz \
    && tar zxvf bison-2.7.tar.gz \
    && cd bison-2.7 \
    && ./configure \
    && make \
    && make install
    
# Install ncurses
RUN set -x \
    && cd /opt/data \
    && wget http://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz \
    && tar zxvf ncurses-5.9.tar.gz \
    && cd ncurses-5.9 \
    && ./configure \
    && make \
    && make install
    
# add group
RUN set -x \
    && groupadd mysql \
    && useradd -g mysql -s /sbin/nologin -M mysql
    
# Download mysql
RUN set -x \
    && cd /opt/data \
    && wget http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.28.tar.gz

# Install mysql
RUN set -x \
    && cd /opt/data \
    && tar zxvf mysql-5.6.28.tar.gz \
    && cd mysql-5.6.28 \
    && cmake . -DCMAKE_INSTALL_PREFIX=/opt/source/mysql/  \
       -DMYSQL_DATADIR=/opt/source/mysql/data  \
       -DWITH_INNOBASE_STORAGE_ENGINE=1  \
       -DMYSQL_TCP_PORT=3306  \
       -DMYSQL_UNIX_ADDR=/opt/source/mysql/data/mysql.sock  \
       -DMYSQL_USER=mysql  \
       -DWITH_DEBUG=0 \
    && make \
    && make install

RUN set -x \
    && cd /opt/source/mysql \
    && chown -R mysql . \
    && chgrp -R mysql . \
    && scripts/mysql_install_db --user=mysql \
       --basedir=/opt/source/mysql \
       --datadir=/opt/source/mysql/data \
    && chown -R root . \ 
    && chown -R mysql ./data \
    && cp /opt/data/mysql-5.6.28/support-files/my-default.cnf /etc/my.cnf

# delete data dir
RUN set -x \
    && rm -rf /opt/data

CMD ["/opt/source/mysql/bin/mysqld_safe", "--user=mysql"]

EXPOSE 3306
