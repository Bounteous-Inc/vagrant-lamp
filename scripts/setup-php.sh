#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

function setup_xdebug() {
    cd /usr/lib
    if [ -d /usr/lib/xdebug ]; then
        rm -rf xdebug
    fi
    git clone git://github.com/xdebug/xdebug.git
    cd xdebug

    if [[ $1 == *"5.6"* ]] ; then
        git checkout xdebug_2_5
    fi

    /opt/phpfarm/inst/php-$1/bin/phpize
    ./configure --with-php-config=/opt/phpfarm/inst/php-$1/bin/php-config
    make
    make install
    if [[ $1 == *"5.4"* ]] ; then
        cat /vagrant/files/xdebug-5.4.txt >> /opt/phpfarm/inst/php-$1/etc/php.ini
    else
        cat /vagrant/files/xdebug.txt >> /opt/phpfarm/inst/php-$1/etc/php.ini
    fi
}


# Setup PHPFARM
cd /opt
if [ ! -d /opt/phpfarm ]; then
    git clone https://github.com/DemacMedia/phpfarm.git phpfarm
fi



# PHP 5.6
if [ ! -f /opt/phpfarm/inst/php-5.6.20/bin/php ]; then
    cd /opt/phpfarm/src
    ./main.sh 5.6.20
    setup_xdebug 5.6.20
    cp /opt/phpfarm/inst/php-5.6.20/etc/php.ini /opt/phpfarm/inst/php-5.6.20/lib/php.ini
fi
if [ ! -f /opt/phpfarm/inst/php-5.6.20/etc/php-fpm.conf ]; then
    cp /vagrant/files/php-fpm-5.6.conf /opt/phpfarm/inst/php-5.6.20/etc/php-fpm.conf
fi
if [ ! -f /etc/init.d/php-5.6 ]; then
    cp /vagrant/files/php-init.d-5.6.sh /etc/init.d/php-5.6
    chmod +x /etc/init.d/php-5.6
    update-rc.d php-5.6 defaults
fi



# PHP 7
# Remove deprecated 7.0.5
if [ -f /opt/phpfarm/inst/php-7.0.5/bin/php ]; then
    rm -Rf /opt/phpfarm/inst/php-7.0.5
fi
if grep -q "php-7.0.5" /etc/init.d/php-7 ; then
    rm /etc/init.d/php-7
fi

# Setup PHP 7.0.6
phpv='7.0.6'
if [ ! -f /opt/phpfarm/inst/php-${phpv}/bin/php ]; then
    cd /opt/phpfarm/src
    ./main.sh ${phpv}
    setup_xdebug ${phpv}
    cp /opt/phpfarm/inst/php-${phpv}/etc/php.ini /opt/phpfarm/inst/php-${phpv}/lib/php.ini
fi
if [ ! -f /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf ]; then
    cp /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf.default /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf
fi
if [ ! -f /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.d/www.conf ]; then
    cp /vagrant/files/php-fpm-7.conf /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.d/www.conf
fi
if [ ! -f /etc/init.d/php-7 ]; then
    cp /vagrant/files/php-init.d-7.sh /etc/init.d/php-7
    chmod +x /etc/init.d/php-7
    update-rc.d php-7 defaults
fi



# PHP 7.1
phpv='7.1.12'
if [ ! -f /opt/phpfarm/inst/php-${phpv}/bin/php ]; then
    cd /opt/phpfarm/src
    ./main.sh ${phpv}
    setup_xdebug ${phpv}
    cp /opt/phpfarm/inst/php-${phpv}/etc/php.ini /opt/phpfarm/inst/php-${phpv}/lib/php.ini
fi
if [ ! -f /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf ]; then
    cp /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf.default /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf
fi
if [ ! -f /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.d/www.conf ]; then
    cp /vagrant/files/php-fpm-7.1.conf /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.d/www.conf
fi
if [ ! -f /etc/init.d/php-7.1 ]; then
    cp /vagrant/files/php-init.d-7.1.sh /etc/init.d/php-7.1
    chmod +x /etc/init.d/php-7.1
    update-rc.d php-7.1 defaults
fi




# Add PHPFarm to PATH
if ! grep -q "phpfarm" /etc/environment ; then
    echo "PATH="$PATH:/opt/phpfarm/inst/bin:/opt/phpfarm/inst/current/bin:/opt/phpfarm/inst/current/sbin"" >> /etc/environment
fi

#set Default Php
/opt/phpfarm/inst/bin/switch-phpfarm 5.6.20
