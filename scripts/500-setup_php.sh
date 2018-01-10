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

function setup_phpfarm() {
    cd /opt
    if [ ! -d /opt/phpfarm ]; then
        git clone https://github.com/DemacMedia/phpfarm.git phpfarm

        # Patch phpfarm options files until I can get a PR put on there to fix these at source:
        if [[ $(/opt/phpfarm/custom/options-5.4.sh | grep 'freetype')  == '' ]]; then
            sed -i "s/--with-png-dir/--with-png-dir \\\\\n--with-freetype-dir=\/usr\/include\/freetype2 \\\\\n--enable-gd-native-ttf/" /opt/phpfarm/custom/options-5.4.sh
        fi
        if [[ $(/opt/phpfarm/custom/options-5.5.sh | grep 'freetype')  == '' ]]; then
            sed -i "s/--with-png-dir/--with-png-dir \\\\\n--with-freetype-dir=\/usr\/include\/freetype2 \\\\\n--enable-gd-native-ttf/" /opt/phpfarm/custom/options-5.5.sh
        fi
        if [[ $(/opt/phpfarm/custom/options-5.6.sh | grep 'freetype')  == '' ]]; then
            sed -i "s/--with-xsl/--with-xsl \\\\\n--with-freetype-dir=\/usr\/include\/freetype2 \\\\\n--enable-gd-native-ttf/" /opt/phpfarm/custom/options-5.6.sh
        fi
        if [[ $(/opt/phpfarm/custom/options-7.sh | grep 'freetype')  == '' ]]; then
            sed -i "s/--with-xsl/--with-xsl \\\\\n--with-freetype-dir=\/usr\/include\/freetype2 \\\\\n--enable-gd-native-ttf/" /opt/phpfarm/custom/options-7.sh
        fi
    fi
}

function setup_php() {
    # Making these local so they dopn't bleed out into the global scope
    local arr
    local conf
    local expected
    local i
    local installed
    local phpv
    local phpn
    local phpp
    local php_config_suffix_escaped
    local prefix
    local processes
    local shortname

    source /vagrant/php_versions.sh

    # Remove any php version not currently shown in php_versions.sh
    for installed in $(ls -d /opt/phpfarm/inst/php-* | cut -d'/' -f5 | cut -d'-' -f2); do
        expected='no';
        for i in "${php_versions[@]}"; do
            arr=(${i// / })
            if [ ${installed} == ${arr[0]} ]; then
                expected='yes'
            fi
        done;
        if [ ${expected} == 'no' ]; then
            # Remove unrequired php
            if [ -f /opt/phpfarm/inst/php-${installed}/bin/php ]; then
                echo "Removing PHP ${installed}"
                rm -Rf /opt/phpfarm/inst/php-${installed}
            fi
            for shortname in $(ls -d /etc/init.d/php-* | cut -d'/' -f4 | cut -d'-' -f2); do
                echo "testing ${shortname}:"
                if grep -q "php-${installed}" /etc/init.d/php-${shortname} ; then
                    echo "Removing PHP init file php-${shortname}"
                    /etc/init.d/php-${shortname} stop || true

                    # This next bit is to ensure that no process keeps the listening port occupied
                    # Otherwise, removing a php version, then vagrant provision, then adding it back and
                    # finally provisioning again causes an error because the requested port is already used
                    prefix=$(cat /etc/init.d/php-${shortname} | grep 'prefix=/opt/phpfarm' | cut -d'=' -f2)
                    conf=$(cat /etc/init.d/php-${shortname} | grep 'php_fpm_CONF=' | cut -d'}' -f2)
                    processes=$(ps aux | grep $prefix$conf | tr -s ' ' | cut -d ' ' -f2)
                    echo "Processes to kill: ${processes}"
                    kill ${processes} || true

                    rm /etc/init.d/php-${shortname}
                fi
            done
        fi
    done;

    # Add new versions of PHP 
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
}

setup_phpfarm
setup_php

# Add PHPFarm to PATH
if ! grep -q "phpfarm" /etc/environment ; then
    echo "PATH="$PATH:/opt/phpfarm/inst/bin:/opt/phpfarm/inst/current/bin:/opt/phpfarm/inst/current/sbin"" >> /etc/environment
fi

# Set Default php to newest available
php_version=$(ls -1 /opt/phpfarm/inst/ | grep php | tail -n1 | cut -d'-' -f2);
/opt/phpfarm/inst/bin/switch-phpfarm ${php_version}
