#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

vagrant_dir="/vagrant"

apt-get update

# Install git
apt-get install -y git

# Setup Apache
bash $vagrant_dir/scripts/setup-apache.sh

# Setup HTOP
apt-get install -y htop

# Setup Redis
apt-get install -y redis-server

# Setup Varnish
bash $vagrant_dir/scripts/setup-varnish.sh

# Setup Percona
bash $vagrant_dir/scripts/setup-percona.sh

#Setup PHP compile pre-requisites
apt-get install -y  build-essential libbz2-dev libmysqlclient-dev libxpm-dev libmcrypt-dev \
    libcurl4-gnutls-dev libxml2-dev libjpeg-dev libpng12-dev libssl-dev pkg-config libreadline-dev \
    curl autoconf libicu-dev libxslt-dev

# Setup PHP w/ xdebug
bash $vagrant_dir/scripts/setup-php.sh

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

# Setup VHOST Script
yes | cp -rf $vagrant_dir/files/vhost.sh /usr/local/bin/vhost
chmod +x /usr/local/bin/vhost

# Restart Apache
service apache2 restart

# Restart Varnish
service varnish restart

# Install RabbitMQ (is used by Enterprise edition)
#apt-get install -y rabbitmq-server
#rabbitmq-plugins enable rabbitmq_management
#invoke-rc.d rabbitmq-server stop
#invoke-rc.d rabbitmq-server start
