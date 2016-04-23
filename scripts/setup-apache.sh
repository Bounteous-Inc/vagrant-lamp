#!/usr/bin/env bash

# Setup Apache
apt-get install -y apache2
a2dismod mpm_prefork mpm_worker
a2dismod php5
a2enmod rewrite actions ssl
a2enmod proxy_fcgi
#Change Listen Port
sed -i.bak 's/Listen 80$/Listen 8090/' /etc/apache2/ports.conf
