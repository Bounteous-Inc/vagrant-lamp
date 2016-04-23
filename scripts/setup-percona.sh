#!/usr/bin/env bash

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
    sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
    service mysql restart
fi