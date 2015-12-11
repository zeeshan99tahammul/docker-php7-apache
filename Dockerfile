##########################################################
# Build image :
# sudo docker build -t mycinema/web .

# Start daemon :
# sudo docker run -d -ti -p 80:80 -v /media/meillet/Epitech/PHP_my_cinema/www:/var/www/site mycinema/web

# Bash :
# sudo docker exec -ti <container> /bin/bash

# host : sudo docker inspect <container> | grep "Gateway"
# Apache & PHP7
#########################################################

FROM ubuntu:14.04
MAINTAINER RobinMeillet <robin.meillet@epitech.eu>

# install packages for Apache and for compiling PHP
RUN apt-get update && apt-get install -y \
    apache2-mpm-prefork \
    apache2-prefork-dev \
    aufs-tools \
    automake \
    bison \
    btrfs-tools \
    build-essential \
    curl \
    git \
    libbz2-dev \
    libcurl4-openssl-dev \
    libmcrypt-dev \
    libxml2-dev \
    re2c

# get the latest PHP source from master branch
RUN git clone --depth=1 https://github.com/php/php-src.git /usr/local/src/php

# we're going to be working out of the PHP src directory for the compile steps
WORKDIR /usr/local/src/php
ENV PHP_DIR /usr/local/php

# configure the build
RUN ./buildconf && ./configure \
    --prefix=$PHP_DIR \
    --with-config-file-path=$PHP_DIR \
    --with-config-file-scan-dir=$PHP_DIR/conf.d \
    --with-apxs2=/usr/bin/apxs2 \
    --with-libdir=/lib/x86_64-linux-gnu \
    --enable-bcmath \
    --with-bz2 \
    --enable-calendar \
    --with-curl \
    --enable-exif \
    --enable-ftp \
    --with-ldap \
    --enable-mbstring \
    --enable-mbregex \
    --with-mcrypt \
    --with-mysqli=mysqlnd \
    --with-openssl \
    --enable-pcntl \
    --without-pear \
    --enable-pdo \
    --with-pdo-mysql=mysqlnd \
    --enable-sockets \
    --with-zip \
    --with-zlib

# compile and install
RUN make && make install

ENV PATH=$PATH:/usr/local/php/bin

# set up Apache environment variables
ENV APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_PID_FILE=/var/run/apache2.pid

# Remove default site and make your conf
RUN rm -f sites-enabled/000-default.conf
ADD apache-config.conf /etc/apache2/sites-enabled/000-default.conf

# Enable additional configs and mods
ENV HTTPD_PREFIX /etc/apache2
RUN a2dismod mpm_event && a2enmod mpm_prefork
RUN ln -s $HTTPD_PREFIX/mods-available/expires.load $HTTPD_PREFIX/mods-enabled/expires.load \
    && ln -s $HTTPD_PREFIX/mods-available/headers.load $HTTPD_PREFIX/mods-enabled/headers.load \
    && ln -s $HTTPD_PREFIX/mods-available/rewrite.load $HTTPD_PREFIX/mods-enabled/rewrite.load

EXPOSE 80

# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND