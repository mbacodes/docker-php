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

* mysqli

* bz2 

* json

* ldap

* mbstring

* pdo_pgsql

* pdo_sqlite

* phar

* imagemagick


# Directory structure

## bin

Bash scripts to ease the some installation processes.
Currently setup for SSHD

## etc

Configuration files

E.g. `/etc/php/opcache.ini` will be used as config for the opcache extension.

#
# How to use this image.

This image includes an SSH-Server to use the PHP-Interpreter during development as remote interpreter in PHPStorm.

The default login is:

User: root
PW: root

The image will use supervisor to run ssh and php-fpm.

```bash
docker run -p 9000:9000 -v <YOUR_CODE_DIRECTORY>:/var/www/html mbacodes/php:7.0.9-fpm
```

## php ini settings

Custom ini settings can be mounted to `/usr/local/etc/php/conf.d/` and will be automatically included.


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
    imgae: mbacodes/php:7.0.9-apache
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
sudo curl -o /Library/LaunchDaemons/com.ralphschindler_10254_alias.plist https://gist.githubusercontent.com/ralphschindler/535dc5916ccbd06f53c1b0ee5a868c93/raw/com.ralphschindler.docker_10254_alias.plist
```


```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ralphschindler_10254_alias</string>
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

Or copy the above Plist file to /Library/LaunchDaemons/com.ralphschindler_10254_alias.plist

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
