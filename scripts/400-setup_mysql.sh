#!/usr/bin/env bash
echo "******************************"
echo "* 400-setup_mysql.sh         *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

# Setup Percona
if [ ! -f /etc/init.d/mysql* ]; then
    wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
    dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
    apt-get update
    echo "percona-server-server-5.6 percona-server-server/root_password password root"       | sudo debconf-set-selections
    echo "percona-server-server-5.6 percona-server-server/root_password_again password root" | sudo debconf-set-selections

    apt-get install -y percona-server-server-5.6 percona-server-client-5.6
    service mysql stop

    sed -i "s/bind-address.*/bind-address    = 0.0.0.0/"           /etc/mysql/my.cnf
    sed -i "s/max_allowed_packet.*/max_allowed_packet      = 64M/" /etc/mysql/my.cnf
    sed -i "s/datadir.*/datadir         = \/srv\/mysql_data/"      /etc/mysql/my.cnf
    if [ ! -d /srv/mysql_data/mysql ]; then
        echo "Moving mysql databases from /var/lib/mysql/ to /srv/mysql_data ..."
        mv /var/lib/mysql/* /srv/mysql_data
    else
        echo "Not moving mysql databases from /var/lib/mysql/ to /srv/mysql_data since data is already present there"
    fi
    service mysql start

    mysql --user="root" --password="root" --execute="GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root';"
    apt-get install -y percona-toolkit
fi

# Setup mysql-sync script
yes | cp -rf /vagrant/files/mysql-sync.sh /usr/local/bin/mysql-sync
chmod +x /usr/local/bin/mysql-sync
