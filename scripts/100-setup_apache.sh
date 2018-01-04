#!/usr/bin/env bash
echo "******************************"
echo "* 100-setup_apache.sh        *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

# Setup Apache
apt-get install -y apache2
a2dismod mpm_prefork mpm_worker
a2enmod rewrite actions ssl headers
a2enmod proxy_fcgi
a2enmod proxy_http

#Change Listen Port
sed -i.bak 's/Listen 80$/Listen 8090/' /etc/apache2/ports.conf

#Change user and groups to vagrant
sed -i.bak 's/www-data$/vagrant/' /etc/apache2/envvars

# Setup VHOST Script
yes | cp -rf /vagrant/files/vhost.sh /usr/local/bin/vhost
chmod +x /usr/local/bin/vhost
