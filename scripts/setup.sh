#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

apt-get update

# Install git
apt-get install -y git

# Setup Apache
bash /vagrant/scripts/setup-apache.sh

# Setup HTOP
apt-get install -y htop

# Setup Redis
bash /vagrant/scripts/setup-redis.sh

# Setup Varnish
bash /vagrant/scripts/setup-varnish.sh

# Setup Percona
bash /vagrant/scripts/setup-percona.sh

# Setup Hosts file
while IFS='' read -r line || [[ -n "$line" ]]; do
  if ! grep -q "$line" /etc/hosts ; then
    echo "$line" >> /etc/hosts
  fi
done </vagrant/files/hosts.txt

#Setup PHP compile pre-requisites
apt-get install -y  build-essential libbz2-dev libmysqlclient-dev libxpm-dev libmcrypt-dev \
    libcurl4-gnutls-dev libxml2-dev libjpeg-dev libpng12-dev libssl-dev pkg-config libreadline-dev \
    curl autoconf libicu-dev libxslt-dev

# Workaround to allow custom scripts added to path with sudo
if ! grep -q "^#Defaults[[:blank:]]*secure_path" /etc/sudoers ; then
    sed -i 's/^Defaults[[:blank:]]*secure_path/#Defaults       secure_path/' /etc/sudoers
fi

# Setup PHP w/ xdebug
bash /vagrant/scripts/setup-php.sh

# Setup Composer
if [ ! -f /usr/local/bin/composer ]; then
    cd /tmp
    curl -sS https://getcomposer.org/installer | /opt/phpfarm/inst/php-5.4.45/bin/php
    mv composer.phar /usr/local/bin/composer
fi

# Setup n98-magerun
if [ ! -f /usr/local/bin/n98 ]; then
    cd /tmp
    wget --progress=bar:force https://files.magerun.net/n98-magerun.phar
    mv n98-magerun.phar /usr/local/bin/n98
fi

# Setup n98-magerun
if [ ! -f /usr/local/bin/modman ]; then
    cd /tmp
    bash < <(curl -s -L https://raw.github.com/colinmollenhour/modman/master/modman-installer)
    mv ~/bin/modman /usr/local/bin/modman
fi

# Restart Services
service apache2 restart
service varnish restart
service php-5.4 restart
service php-5.5 restart
service php-5.6 restart
service php-7 restart

