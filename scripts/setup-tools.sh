#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

# Setup Composer
if [ ! -f /usr/local/bin/composer ]; then
    cd /tmp
    curl -sS https://getcomposer.org/installer | /opt/phpfarm/inst/php-5.4.45/bin/php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
fi

# Setup n98-magerun
if [ ! -f /usr/local/bin/n98 ]; then
    cd /tmp
    wget --progress=bar:force https://files.magerun.net/n98-magerun.phar
    mv n98-magerun.phar /usr/local/bin/n98
    chmod +x /usr/local/bin/n98
fi

# Setup n98-magerun
if [ ! -f /usr/local/bin/modman ]; then
    cd /tmp
    bash < <(curl -s -L https://raw.github.com/colinmollenhour/modman/master/modman-installer)
    mv ~/bin/modman /usr/local/bin/modman
    chmod +x /usr/local/bin/modman
fi

# Setup PHPUnit
if [ ! -f /usr/local/bin/phpunit ]; then
    cd /tmp
    wget --progress=bar:force https://phar.phpunit.de/phpunit.phar
    mv phpunit.phar /usr/local/bin/phpunit
    chmod +x /usr/local/bin/phpunit
fi