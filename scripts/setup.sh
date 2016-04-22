#!/usr/bin/env bash

function package_exists() {
    return dpkg -l "$1" &> /dev/null
}

# Enable trace printing and exit on the first error
set -ex

vagrant_dir="/vagrant"

apt-get update

# Install git
apt-get install -y git

# Setup Apache
apt-get install -y apache2
a2enmod rewrite
sed -i.bak 's/.*Listen.*/Listen '8090'/' /etc/apache2/ports.conf


# Setup HTOP
apt-get install -y htop

# Setup Varnish
apt-get install -y varnish

# Setup Percona
if [ ! -f /etc/mysql/my.cnf ]; then
    gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
    gpg -a --export CD2EFD2A | sudo apt-key add -
    if ! grep -q "http://repo.percona.com/apt trusty main" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        bash -c 'echo deb http://repo.percona.com/apt trusty main >> /etc/apt/sources.list'
        bash -c 'echo deb-src http://repo.percona.com/apt trusty main >> /etc/apt/sources.list'
    fi
    apt-get update
    echo "percona-server-server-5.6 percona-server-server/root_password password root" | sudo debconf-set-selections
    echo "percona-server-server-5.6 percona-server-server/root_password_again password root" | sudo debconf-set-selections
    apt-get install -y percona-server-server-5.6 percona-server-client-5.6
fi


#Setup PHP compile pre-requisites
apt-get install -y  build-essential libbz2-dev libmysqlclient-dev libxpm-dev libmcrypt-dev \
    libcurl4-gnutls-dev libxml2-dev libjpeg-dev libpng12-dev libssl-dev pkg-config libreadline-dev \
    curl autoconf

# Setup PHPFARM
cd /opt
if [ ! -d /opt/phpfarm ]; then
    git clone https://github.com/DemacMedia/phpfarm.git phpfarm
fi
cd /opt/phpfarm/src
if [ ! -f /opt/phpfarm/inst/php-5.4.45/bin/php ]; then
    ./main.sh 5.4.45
    #PHP 5.4 uses lib instead of etc for php.ini
    mv /opt/phpfarm/inst/php-5.4.45/etc/php.ini /opt/phpfarm/inst/php-5.4.45/lib/php.ini
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
if ! grep -q "phpfarm" /home/vagrant/.bashrc ; then
    echo "PATH="$PATH:/opt/phpfarm/inst/bin:/opt/phpfarm/inst/current/bin:/opt/phpfarm/inst/current/sbin"" >> /home/vagrant/.bashrc
fi

#Setup Xdebug
cd /usr/lib
if [ ! -d /usr/lib/xdebug ]; then
    git clone git://github.com/xdebug/xdebug.git
fi

cd xdebug

if ! grep -q xdebug /opt/phpfarm/inst/php-5.4.45/lib/php.ini ; then
    /opt/phpfarm/inst/php-5.4.45/bin/phpize
    ./configure --enable-xdebug --with-php-config=/opt/phpfarm/inst/php-5.4.45/bin/php-config
    make
    make install
    cat /vagrant/files/xdebug-5.4.txt >> /opt/phpfarm/inst/php-5.4.45/lib/php.ini
fi

if ! grep -q xdebug /opt/phpfarm/inst/php-5.5.34/etc/php.ini ; then
    /opt/phpfarm/inst/php-5.5.34/bin/phpize
    ./configure --enable-xdebug --with-php-config=/opt/phpfarm/inst/php-5.5.34/bin/php-config
    make
    make install
    cat /vagrant/files/xdebug.txt >> /opt/phpfarm/inst/php-5.5.34/etc/php.ini
fi

if ! grep -q xdebug /opt/phpfarm/inst/php-5.6.20/etc/php.ini ; then
    /opt/phpfarm/inst/php-5.6.20/bin/phpize
    ./configure --enable-xdebug --with-php-config=/opt/phpfarm/inst/php-5.6.20/bin/php-config
    make
    make install
    cat /vagrant/files/xdebug.txt >> /opt/phpfarm/inst/php-5.6.20/etc/php.ini
fi
if ! grep -q xdebug /opt/phpfarm/inst/php-7.0.5/etc/php.ini ; then
    /opt/phpfarm/inst/php-7.0.5/bin/phpize
    ./configure --enable-xdebug --with-php-config=/opt/phpfarm/inst/php-7.0.5/bin/php-config
    make
    make install
    cat /vagrant/files/xdebug.txt >> /opt/phpfarm/inst/php-7.0.5/etc/php.ini
fi

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

# Restart Apache
service apache2 restart

# Restart Varnish
service varnish restart

# Install RabbitMQ (is used by Enterprise edition)
#apt-get install -y rabbitmq-server
#rabbitmq-plugins enable rabbitmq_management
#invoke-rc.d rabbitmq-server stop
#invoke-rc.d rabbitmq-server start
