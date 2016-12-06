# PHP docker image based on the [offical php image](https://hub.docker.com/_/php/)


# Installed PHP Extension

* mcrypt

* intl

* curl

* xdebug

* gd

* opcache

* pdo

* pdo_mysql

* bcmath 

* bz2 

* json

* ldap

* mbstring

* pdo_pgsql

* pdo_sqlite

* phar

* imagemagick


# Installed tools

* composer

# Directory structure

## bin

Bash scripts to ease the some installation processes.
Currently setup for SSHD

## etc

Configuration files

E.g. `/etc/php/oci.ini` will be used as config for the oci8 extension.

## oracle


# How to use build image.

Check out from VCS
In the project root run 

```bash
mvn docker:build
```


# How to use this image.

This image includes an SSH-Server to use the PHP-Interpreter during development as remote interpreter in PHPStorm.

The default login is:

User: root
PW: root

The image will use supervisor to run ssh and php-fpm.

```bash
docker run -p 80:80 -p 443:443 -v <YOUR_CODE_DIRECTORY>:/var/www/html mbacodes/php:7.0.9-fpm
```

## php ini settings

Custom ini settings can be mounted to `/usr/local/etc/php/conf.d/` and will be automatically included.

E.g. 

```bash
docker run -p 80:80 -p 443:443 -v <YOUR_CODE_DIRECTORY>:/var/www/html -v <YOUR_CUSTOM_INI_FILES_DIR>/custom.ini:/usr/local/etc/php/conf.d/99-custom.ini mbacodes/php:latest
```

## Xdebug

When using xdebug and docker for mac there are some difficulties due to the restricted access of the container to the 
host systems network.

To workaround this issue an environment variable `XDEBUG_REMOTE_HOST` can be used.

1. setup an alias IP for the loopback device (localhost / 127.0.0.1) `sudo ifconfig lo0 alias 10.254.254.254`.
2. pass the IP of the loopback alias to the container using environment variables   
e.g in the `docker-compose.yml`

```yml
...

 php:
    imgae: php:7.0.8-fpm-oci8
    volumes:
      - ./src:/var/www/html
    environment:
      - XDEBUG_REMOTE=10.254.254.254
```

###  Docker (Mac) De-facto Standard Host Address Alias

This launchd script will ensure that your Docker environment on your Mac will have 10.254.254.254 as an alias on your loopback device (127.0.0.1).  The command being run is `ifconfig lo0 alias 10.254.254.254`

#### Installation

Take a look at [Ralph Schindlers - Docker (Mac) De-facto Standard Host Address Alias](https://gist.github.com/ralphschindler/535dc5916ccbd06f53c1b0ee5a868c93)  
Short version below.

```
You may want to change the IP-address if it's already in use on your system.
```

Copy/Paste the following in terminal with sudo (must be root as the target directory is owned by root)...

```bash
sudo curl -o /Library/LaunchDaemons/de.kochan.docker_10254_alias.plist https://gist.githubusercontent.com/ralphschindler/535dc5916ccbd06f53c1b0ee5a868c93/raw/com.ralphschindler.docker_10254_alias.plist
```


```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>de.kochan.docker_10254_alias</string>
    <key>ProgramArguments</key>
    <array>
        <string>ifconfig</string>
        <string>lo0</string>
        <string>alias</string>
        <string>10.254.254.254</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

Or copy the above Plist file to /Library/LaunchDaemons/de.kochan.docker_10254_alias.plist

Next and every successive reboot will ensure your lo0 will have the proper ip address.

#### Why?

Because `docker.local` is gone. This seems to be the easiest way to setup xdebug to connect back to your IDE running on your host.  Similarly, this is a solution for any kind of situations where a container needs to connect back to the host container at a known ip address.

For example, a configuration for xdebug in your php container for xdebug.ini might look like:

```ini
zend_extension=xdebug.so
xdebug.remote_host=10.254.254.254
xdebug.remote_enable=1
xdebug.remote_autostart=1
```

Also, your nginx and docker-compose would include an environment variable much like `PHP_IDE_CONFIG="serverName=localhost"`


## docker-compose.yml example

```yml
version: '2'
services:
  nginx-proxy:
    image: jwilder/nginx-proxy
    ports:
      - 80:80
      - 1025:1025
      - 8025:8025
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
  mail:
    image: mailhog/mailhog
    environment:
      - VIRTUAL_HOST=mail.docker.dev
      - VIRTUAL_PORT=1025,8025
  php:
    image: php:7.0.8-fpm-oci8
    depends_on:
      - mail
    volumes:
      - ./etc/php/custom.ini:/usr/local/etc/php/conf.d/99-custom.ini
      - ./src:/var/www/html
    ports:
      - "2229:22"
    environment:
      - XDEBUG_REMOTE_HOST=10.254.254.254
      - SSH_ROOT_PASSWORD=toor
  nginx:
    image: nginx:1.11
    depends_on:
      - php
    volumes:
      - ./etc/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf
      - ./src:/var/www/html
    environment:
      - VIRTUAL_HOST=docker.dev
  database:
    image: mariadb:latest
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=test
    volumes:
      - ./etc/mysql/my.conf:/etc/mysql/my.conf
      - ./data/db:/var/lib/mysql
```



## With Command Line

### How to install more PHP extensions

We provide the helper scripts `docker-php-ext-configure`, `docker-php-ext-install`, and `docker-php-ext-enable` to more easily install PHP extensions.

In order to keep the images smaller, PHP's source is kept in a compressed tar file. To facilitate linking of PHP's source with any extension, we also provide the helper script `docker-php-source` to easily extract the tar or delete the extracted source. Note: if you do use `docker-php-source` to extract the source, be sure to delete it in the same layer of the docker image.

```Dockerfile
FROM php:7.0-apache
RUN docker-php-source extract \
	# do important things \
	&& docker-php-source delete
```

#### PHP Core Extensions

For example, if you want to have a PHP-FPM image with `iconv`, `mcrypt` and `gd` extensions, you can inherit the base image that you like, and write your own `Dockerfile` like this:

```dockerfile
FROM php:7.0-fpm
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd
```

Remember, you must install dependencies for your extensions manually. If an extension needs custom `configure` arguments, you can use the `docker-php-ext-configure` script like this example. There is no need to run `docker-php-source` manually in this case, since that is handled by the `configure` and `install` scripts.

#### PECL extensions

Some extensions are not provided with the PHP source, but are instead available through [PECL](https://pecl.php.net/). To install a PECL extension, use `pecl install` to download and compile it, then use `docker-php-ext-enable` to enable it:

```dockerfile
FROM php:7.0-fpm
RUN apt-get update && apt-get install -y libmemcached-dev \
	&& pecl install memcached \
	&& docker-php-ext-enable memcached
```

#### Other extensions

Some extensions are not provided via either Core or PECL; these can be installed too, although the process is less automated:

```dockerfile
FROM php:7.0-apache
RUN curl -fsSL 'https://xcache.lighttpd.net/pub/Releases/3.2.0/xcache-3.2.0.tar.gz' -o xcache.tar.gz \
    && mkdir -p xcache \
    && tar -xf xcache.tar.gz -C xcache --strip-components=1 \
    && rm xcache.tar.gz \
    && ( \
        cd xcache \
        && phpize \
        && ./configure --enable-xcache \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r xcache \
    && docker-php-ext-enable xcache
```

### Without a `Dockerfile`

If you don't want to include a `Dockerfile` in your project, it is sufficient to do the following:

```console
$ docker run -d -p 80:80 --name my-apache-php-app -v "$PWD":/var/www/html php:7.0-apache
```

# Image Variants

The `php` images come in many flavors, each designed for a specific use case.

## `php:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

## `php:alpine`

# License

View [license information](http://php.net/license/) for the software contained in this image.

# Supported Docker versions

This image is officially supported on Docker version 1.12.0.

Support for older versions (down to 1.6) is provided on a best-effort basis.

Please see [the Docker installation documentation](https://docs.docker.com/installation/) for details on how to upgrade your Docker daemon.

# Known Issues

See https://docs.docker.com/docker-for-mac/troubleshoot/#/known-issues

PHPStorm can't connect to the docker-api through a socket.
To work around this issue you can use a docker container providing this socket connection via tcp

Here some example aliases to eas the process

Initialize a container providing the api under the name of dockerapi
```bash
alias doapiinit='docker run -d -v /var/run/docker.sock:/var/run/docker.sock --name dockerapi -p 127.0.0.1:2376:2375 bobrik/socat TCP4-LISTEN:2375,fork,reuseaddr UNIX-CONNECT:/var/run/docker.sock && export DOCKER_HOST=tcp://localhost:2376'
```

If initialized, start the api container

```bash
alias doapistart='docker start dockerapi && export DOCKER_HOST=tcp://localhost:2376'
```

stop the api container
```bash
alias doapistop='unset DOCKER_HOST && docker stop dockerapi'
```



