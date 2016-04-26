#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

# Setup Apache
apt-get install -y apache2
a2dismod mpm_prefork mpm_worker
a2enmod rewrite actions ssl
a2enmod proxy_fcgi

#Change Listen Port
sed -i.bak 's/Listen 80$/Listen 8090/' /etc/apache2/ports.conf

# Setup VHOST Script
yes | cp -rf /vagrant/files/vhost.sh /usr/local/bin/vhost
chmod +x /usr/local/bin/vhost