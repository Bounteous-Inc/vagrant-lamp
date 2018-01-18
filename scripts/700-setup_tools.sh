#!/usr/bin/env bash
echo "******************************"
echo "* 700-setup_tools.sh         *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

# Setup Composer
if [ ! -f /usr/local/bin/composer ]; then
    cd /tmp
    php=/opt/phpfarm/inst/php-$(ls -1 /opt/phpfarm/inst/ | grep php | head -n1 | cut -d'-' -f2)/bin/php;
    curl -sS https://getcomposer.org/installer | ${php}
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
fi

# Set up n98 for M1, M2 and automatic selection based on platform in use
if [ ! -f /usr/local/bin/n98 ] || [ ! -f /usr/local/bin/n98-1 ] || [ ! -f /usr/local/bin/n98-2 ]; then
    cd /tmp
    rm -f n98-magerun*

    wget --progress=bar:force https://files.magerun.net/n98-magerun.phar
    mv n98-magerun.phar /usr/local/bin/n98-1
    chmod +x /usr/local/bin/n98-1

    wget --progress=bar:force https://files.magerun.net/n98-magerun2.phar
    mv n98-magerun2.phar /usr/local/bin/n98-2
    chmod +x /usr/local/bin/n98-2

    cp /vagrant/files/n98 /usr/local/bin/n98
    chmod +x /usr/local/bin/n98
fi

# Setup modman
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
