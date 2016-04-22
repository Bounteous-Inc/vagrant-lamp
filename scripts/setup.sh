#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

vagrant_dir="/vagrant"

apt-get update

# Install git
apt-get install -y git

# Setup Apache
apt-get install -y apache2
a2enmod rewrite

apt-get install -y  build-essential libbz2-dev libmysqlclient-dev libxpm-dev libmcrypt-dev \
    libcurl4-gnutls-dev libxml2-dev libjpeg-dev libpng12-dev libssl-dev pkg-config libreadline-dev

# Setup PHPFARM
cd /opt
if [ ! -d /opt/phpfarm ]; then
    git clone https://github.com/DemacMedia/phpfarm.git phpfarm
fi
cd /opt/phpfarm/src
if [ ! -f /opt/phpfarm/inst/php-5.3.29/bin/php ]; then
    ./main.sh 5.3.29
fi
if [ ! -f /opt/phpfarm/inst/php-5.4.45/bin/php ]; then
    ./main.sh 5.4.45
fi
if [ ! -f /opt/phpfarm/inst/php-5.5.34/bin/php ]; then
    ./main.sh 5.5.34
fi
if [ ! -f /opt/phpfarm/inst/php-5.6.20/bin/php ]; then
    ./main.sh 5.6.20
fi
if [ ! -f /opt/phpfarm/inst/php-7.0.5/bin/php ]; then
    ./main.sh 7.0.5
fi

#cd /usr/lib
#git clone git://github.com/xdebug/xdebug.git
#cd xdebug
#phpize
#./configure --enable-xdebug
#make
#make install
## Configure XDebug to allow remote connections from the host
#touch /etc/php/7.0/cli/conf.d/20-xdebug.ini
#echo 'zend_extension=/usr/lib/xdebug/modules/xdebug.so
#xdebug.max_nesting_level=200
#xdebug.remote_enable=1
#xdebug.remote_connect_back=1' >> /etc/php/7.0/cli/conf.d/20-xdebug.ini
#echo "date.timezone = America/Chicago" >> /etc/php/7.0/cli/php.ini
#rm -rf /etc/php/7.0/apache2
#ln -s /etc/php/7.0/cli /etc/php/7.0/apache2

# Restart Apache
#service apache2 restart

# Setup MySQL
#debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
#debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'
#apt-get install -q -y mysql-server-5.6 mysql-client-5.6
#mysqladmin -uroot -ppassword password ''
# Make it possible to run 'mysql' without username and password
#sed -i '/\[client\]/a \
#user = root \
#password =' /etc/mysql/my.cnf

# Setup Composer
#if [ ! -f /usr/local/bin/composer ]; then
#    cd /tmp
#    curl -sS https://getcomposer.org/installer | php
#    mv composer.phar /usr/local/bin/composer
#fi

# Install RabbitMQ (is used by Enterprise edition)
#apt-get install -y rabbitmq-server
#rabbitmq-plugins enable rabbitmq_management
#invoke-rc.d rabbitmq-server stop
#invoke-rc.d rabbitmq-server start
