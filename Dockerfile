########################################################################################################################
## PHP
FROM php:7.0.10-apache

RUN sed -i "s/httpredir.debian.org/mirror.unitedcolo.de/" /etc/apt/sources.list

RUN apt-get update && \
    apt-get install -y \
        unzip \
        libaio-dev \
        libmcrypt-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng12-dev \
        libicu-dev \
        libcurl4-gnutls-dev \
        imagemagick \
        libmagickwand-dev  \
        libpq-dev \
        sqlite3 \
        libsqlite3-dev \
        libldap2-dev \
    && ln -f -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && docker-php-ext-configure mysqli \
    && docker-php-ext-install -j$(nproc) mysqli \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) opcache \
    && docker-php-ext-install -j$(nproc) bcmath \
    && docker-php-ext-install -j$(nproc) bz2 \
    && docker-php-ext-install -j$(nproc) json \
    && docker-php-ext-install -j$(nproc) mbstring \
    && docker-php-ext-install -j$(nproc) pdo_pgsql \
    && docker-php-ext-install -j$(nproc) pdo_sqlite \
    && docker-php-ext-install -j$(nproc) ldap \
    && docker-php-ext-install -j$(nproc) phar

# Xdebug and imagick
RUN pecl install xdebug && pecl install imagick

########################################################################################################################
## SSH
ENV SSH_ROOT_PASSWORD root

# Install OpenSSH to use this php as remote interpreter in IDE's
ADD bin/set-root-password.sh /usr/local/bin/set-root-password.sh
RUN chmod a+x /usr/local/bin/set-root-password.sh  \
    && /usr/local/bin/set-root-password.sh \
    && apt-get update \
    && apt-get install -y openssh-server supervisor \
    && mkdir -p /var/run/sshd \
    && sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/session\s*required\s*pam_loginuid.so/session optional pam_loginuid.so/g' /etc/pam.d/sshd \
    && echo 'export VISIBLE=now' >> /etc/profile

########################################################################################################################
## supervisor
ADD etc/supervisor/sshd.conf /etc/supervisor/conf.d/sshd.conf
ADD etc/supervisor/apache.conf /etc/supervisor/conf.d/apache.conf
ADD etc/supervisor/rootpassword.conf /etc/supervisor/conf.d/rootpassword.conf

########################################################################################################################
## apache modules
# Enable mod_rewrite
RUN a2enmod rewrite ssl

########################################################################################################################
## php configs
ADD etc/php/opcache.ini /usr/local/etc/php/conf.d/10-opcache.ini
ADD etc/php/xdebug.ini /usr/local/etc/php/conf.d/40-xdebug.ini
ADD etc/php/imagick.ini /usr/local/etc/php/conf.d/50-imagick.ini


EXPOSE 22
EXPOSE 80
EXPOSE 443

CMD ["/usr/bin/supervisord", "-n"]