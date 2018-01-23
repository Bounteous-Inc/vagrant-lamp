#!/usr/bin/env bash
echo "******************************"
echo "* 100-setup_apache.sh        *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

# Setup Apache
apt-get install -y apache2 2>&1
a2dismod mpm_prefork mpm_worker
a2enmod rewrite actions ssl headers
a2enmod proxy_fcgi
a2enmod proxy_http

# Change Listen Port
sed -i.bak 's/Listen 80$/Listen 8090/' /etc/apache2/ports.conf

# Change user and groups to vagrant
sed -i.bak 's/www-data$/vagrant/' /etc/apache2/envvars
if [ -f /etc/apache2/sites-available/default-ssl.conf ]; then
    rm /etc/apache2/sites-available/default-ssl.conf
fi

# Setup VHOST Script
yes | cp -rf /vagrant/files/vhost.sh /usr/local/bin/vhost
chmod +x /usr/local/bin/vhost

# Upgrade older vhost entries to support SSL and to be picked up by `backupWebconfig` command
function upgrade_vhosts() {
    local a
    local arr
    local config
    local configs
    local config_php
    local d
    local i
    local n
    local p
    local port
    local phpn
    local phpp
    local phpv

    # Remove duplicate Mailhog configuration if present:
    if [ -f /etc/apache2/sites-enabled/mailhog.demacmedia.com.conf ] && [ -f /etc/apache2/sites-enabled/100-mailhog.demacmedia.com.conf ]; then
        rm -f /etc/apache2/sites-enabled/mailhog.demacmedia.com.conf
        rm -f /etc/apache2/sites-available/mailhog.demacmedia.com.conf
    fi

    # Find all legacy site configs not prefixed with n00-
    if [ ' '$(ls -1 /etc/apache2/sites-enabled/*.conf | grep '00-' -v) = ' ' ]; then
        echo "No legacy vhosts to upgrade"
    else
        echo "Upgrading legacy vhosts to support SSL"
        configs="$(ls -1 /etc/apache2/sites-enabled/*.conf | grep '00-' -v)"
        source /vagrant/config_php.sh
        for config in ${configs[@]} ; do
            filename=${config}
            file=$(cat $filename)
            a=$(echo "$file" | grep 'ServerAlias' | head -n1 | xargs | cut -d' ' -f2)
            d=$(echo "$file" | grep 'DocumentRoot' | head -n1 | xargs | cut -d' ' -f2)
            n=$(echo "$file" | grep 'ServerName ' | head -n1 | xargs | cut -d' ' -f2)
            port=$(echo "$file" | grep '<Proxy fcgi://127.0.0.1:' | xargs | head -n1 | cut -d':' -f3 | cut -d'>' -f1)
            p='?'
            for i in "${config_php[@]}"; do
                arr=(${i// / })
                phpv=${arr[0]}
                phpn=${arr[1]}
                phpp=${arr[2]}
                if [ "${port}" = "${phpp}" ]; then
                    p=${phpn}
                fi
            done;
            echo "Upgrading existing vhost ${filename}..."
            if [ "$p" = "?" ]; then
                echo "Unsupported PHP version for port ${port}"
            else
                if [ "$a" = "" ]; then
                    echo "vhost add -d $d -n $n -p $p -f"
                    vhost add -d $d -n $n -p $p -f
                else
                    echo "vhost add -d $d -n $n -p $p -a $a -f"
                    vhost add -d $d -n $n -p $p -a $a -f
                fi
            fi
        done
    fi
}

upgrade_vhosts

