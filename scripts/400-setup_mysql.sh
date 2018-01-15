#!/usr/bin/env bash
echo "******************************"
echo "* 400-setup_mysql.sh         *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

# If mysql is already here, move existing data to /srv/mysql/data and change my.cnf to point there
if [ -f /etc/init.d/mysql* ]; then
    service mysql stop

    sed -i "s/datadir.*/datadir         = \/srv\/mysql\/data/"     /etc/mysql/my.cnf
    if [ ! -d /srv/mysql/data/mysql ]; then
        echo "Copying mysql databases from /var/lib/mysql/ to /srv/mysql/data ..."
        cp -r /var/lib/mysql/* /srv/mysql/data
    else
        echo "Not moving mysql databases from /var/lib/mysql/ to /srv/mysql/data since data is already present there"
    fi
    service mysql start

    # Get password for debian-sys-maintainer in case we have existing databases which need to have this set to a new value
    debian_sys_maint_pwd=`sudo grep password /etc/mysql/debian.cnf | head -n1 | cut -d' ' -f3`
    export MYSQL_PWD='root'
    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root';" | mysql -u'root'
    echo "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '${debian_sys_maint_pwd}';" | mysql -u'root'
    export MYSQL_PWD=''
fi


if [ ! -f /etc/init.d/mysql* ]; then
    wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
    dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
    apt-get update
    echo "percona-server-server-5.6 percona-server-server/root_password password root"       | sudo debconf-set-selections
    echo "percona-server-server-5.6 percona-server-server/root_password_again password root" | sudo debconf-set-selections

    apt-get install -y percona-server-server-5.6 percona-server-client-5.6 2>&1
    service mysql stop

    sed -i "s/bind-address.*/bind-address    = 0.0.0.0/"           /etc/mysql/my.cnf
    sed -i "s/max_allowed_packet.*/max_allowed_packet      = 64M/" /etc/mysql/my.cnf
    sed -i "s/datadir.*/datadir         = \/srv\/mysql\/data/"     /etc/mysql/my.cnf
    echo "Copying mysql databases from /var/lib/mysql/ to /srv/mysql/data ..."
    cp -r /var/lib/mysql/* /srv/mysql/data

    service mysql start

    export MYSQL_PWD='root'
    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root';" | mysql -u'root'
    export MYSQL_PWD=''
fi

# Make mysql's socket available to php - e.g. 
# echo "<?php \$li = new mysqli('localhost', 'root', 'root', 'mysql'); ?>" | php
if [ ! -L /tmp/mysql.sock ]; then
    echo "Creating symbolic link for php to connect to mysql.sock"
    ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock
fi

apt-get install -y percona-toolkit 2>&1


# Setup mysql-sync script
yes | cp -rf /vagrant/files/mysql-sync.sh /usr/local/bin/mysql-sync
chmod +x /usr/local/bin/mysql-sync
