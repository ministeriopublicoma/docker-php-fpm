FROM php:5.6.40-fpm
MAINTAINER Ricardo Coelho <rcoelho@mpma.mp.br>

COPY assets/oracle /opt/oracle/
COPY assets/pdo_oci /opt/oracle/pdo_oci/
COPY assets/php.ini /usr/local/etc/php/
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        git \
        sudo \
        libpq-dev \
        libicu-dev \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxslt1-dev \
        libldb-dev \
	libldap2-dev \
        libmemcached-dev \
        freetds-dev \        
        build-essential \
        libaio1 \
        libldap2-dev \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
    && docker-php-ext-install -j$(nproc) pgsql pdo_pgsql pdo_mysql ldap xsl gettext mysqli \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd intl zip \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer \
    && gunzip /opt/oracle/instantclient_12_2/*.gz \
    && ln /opt/oracle/instantclient_12_2/libclntsh.so.12.1 /opt/oracle/instantclient_12_2/libclntsh.so \
    && ln /opt/oracle/instantclient_12_2/libocci.so.12.1 /opt/oracle/instantclient_12_2/libocci.so \
    && echo /opt/oracle/instantclient_12_2 > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && echo /opt/oracle/instantclient_12_2/sdk >> /etc/ld.so.conf.d/oracle-instantclient.conf \
    && echo /opt/oracle/instantclient_12_2/sdk/include >> /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig \
    && echo "instantclient,/opt/oracle/instantclient_12_2" | pecl install oci8-2.0.12 \
    && cd /opt/oracle/pdo_oci \
    && phpize \
    && ORACLE_HOME=/opt/oracle/instantclient_12_2/sdk ./configure --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_2,12.2 \
    && sed -i 's_/lib/oracle/12.2/client/lib__g' Makefile \
    && make \
    && make install \
    && docker-php-ext-configure pdo_dblib --with-libdir=/lib/x86_64-linux-gnu \
    && docker-php-ext-install pdo_dblib \
    && docker-php-ext-install bcmath \
    && yes "no" | pecl install -f -o lzf \
    && yes "yes" | pecl install -f -o igbinary-2.0.8 \
    && yes "yes" | pecl install -f -o redis-4.3.0 \
    && pecl install memcached-2.2.0 \
    && docker-php-ext-enable lzf igbinary-2.0.8 redis-4.3.0 \
    && docker-php-ext-enable oci8 pdo_oci memcached

