#!/usr/bin/env bash
echo "******************************"
echo "* 500-setup_php.sh           *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

function setup_xdebug() {
    cd /usr/lib
    if [ -d /usr/lib/xdebug ]; then
        rm -rf xdebug
    fi
    git clone git://github.com/xdebug/xdebug.git
    cd xdebug

    if [[ $1 == *"5.4"* ]] ; then
        git checkout xdebug_2_3
    fi

    if [[ $1 == *"5.5"* ]] ; then
        git checkout xdebug_2_4
    fi

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


# Remove deprecated 7.0.5
if [ -f /opt/phpfarm/inst/php-7.0.5/bin/php ]; then
    rm -Rf /opt/phpfarm/inst/php-7.0.5
fi
if grep -q "php-7.0.5" /etc/init.d/php-7 ; then
    rm /etc/init.d/php-7
fi

source /vagrant/php_versions.sh

for i in "${php_versions[@]}"; do
    arr=(${i// / })
    phpv=${arr[0]}
    phpn=${arr[1]}
    phpp=${arr[2]}

    if [ ! -f /opt/phpfarm/inst/php-${phpv}/bin/php ]; then
        cd /opt/phpfarm/src
        ./main.sh ${phpv}
        setup_xdebug ${phpv}
        cp /opt/phpfarm/inst/php-${phpv}/etc/php.ini /opt/phpfarm/inst/php-${phpv}/lib/php.ini
    fi
    if [ ${phpv:0:1} == 5 ]; then
        php_config_suffix_escaped="\/etc\/php-fpm.conf"
        if [ ! -f /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf ]; then
            cp /vagrant/files/php-fpm-xxx.conf /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf
            sed -i "s/###phpv###/${phpv}/g"    /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf
            sed -i "s/###phpn###/${phpn}/g"    /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf
            sed -i "s/###phpp###/${phpp}/g"    /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf
        fi
    else
        php_config_suffix_escaped="\/etc\/php-fpm.d\/www.conf"
        if [ ! -f /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf ]; then
            cp /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf.default /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.conf
        fi
        if [ ! -f /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.d/www.conf ]; then
            cp /vagrant/files/php-fpm-xxx.conf /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.d/www.conf
            sed -i "s/###phpv###/${phpv}/g"    /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.d/www.conf
            sed -i "s/###phpn###/${phpn}/g"    /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.d/www.conf
            sed -i "s/###phpp###/${phpp}/g"    /opt/phpfarm/inst/php-${phpv}/etc/php-fpm.d/www.conf
        fi
    fi
    if [ ! -f /etc/init.d/php-${phpn} ]; then
        cp /vagrant/files/php-init.d-xxx.sh /etc/init.d/php-${phpn}
        sed -i "s/###phpv###/${phpv}/g" /etc/init.d/php-${phpn}
        sed -i "s/###php_config_suffix###/${php_config_suffix_escaped}/g" /etc/init.d/php-${phpn}
        chmod +x /etc/init.d/php-${phpn}
        update-rc.d php-${phpn} defaults
    fi
done



# Add PHPFarm to PATH
if ! grep -q "phpfarm" /etc/environment ; then
    echo "PATH="$PATH:/opt/phpfarm/inst/bin:/opt/phpfarm/inst/current/bin:/opt/phpfarm/inst/current/sbin"" >> /etc/environment
fi



# Set Default php to oldest available
php_version=$(ls -1 /opt/phpfarm/inst/ | grep php | head -n1 | cut -d'-' -f2);
/opt/phpfarm/inst/bin/switch-phpfarm ${php_version}
