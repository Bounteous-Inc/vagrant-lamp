#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

# Setup Percona
if [ ! -f /etc/init.d/mysql* ]; then
    wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
    dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
    apt-get update
    echo "percona-server-server-5.6 percona-server-server/root_password password root" | sudo debconf-set-selections
    echo "percona-server-server-5.6 percona-server-server/root_password_again password root" | sudo debconf-set-selections
    apt-get install -y percona-server-server-5.6 percona-server-client-5.6
    sed -i "s/bind-address.*/bind-address    = 0.0.0.0/"           /etc/mysql/my.cnf
    sed -i "s/max_allowed_packet.*/max_allowed_packet      = 64M/" /etc/mysql/my.cnf
    service mysql restart
    mysql --user="root" --password="root" --execute="GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root';"
    apt-get install -y percona-toolkit
fi

# Setup mysql-sync script
yes | cp -rf /vagrant/files/mysql-sync.sh /usr/local/bin/mysql-sync
chmod +x /usr/local/bin/mysql-sync