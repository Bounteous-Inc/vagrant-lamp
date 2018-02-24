#!/usr/bin/env bash
echo "******************************"
echo "*       setup_solr.sh        *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

# Install Tomcat 7

if [ ! -f /etc/tomcat7/tomcat-users.xml ]; then
    apt-get -y install tomcat7 tomcat7-admin 2>&1
    sed -i 's|</tomcat-users>|  <role rolename="admin-gui,manager-gui"/>\n  <user username="vagrant" password="vagrant" roles="admin-gui,manager-gui"/>\n</tomcat-users>|' /etc/tomcat7/tomcat-users.xml
    service tomcat7 restart
fi

#install solr
if [ ! -d /opt/solr ]; then
    cd /opt/
    wget --progress=bar:force https://github.com/DemacMedia/vagrant-lamp-assets/releases/download/v1.0/solr.tar.gz
    if [ -f /opt/solr.tar.gz ]; then
        tar -zxf solr.tar.gz
        chown -R tomcat7:tomcat7 /opt/solr
        cp /opt/solr/extra/* /etc/tomcat7/Catalina/localhost/
        service tomcat7 restart
    fi
fi

if [ ! -f /etc/apache2/sites-available/100-solr.demacmedia.com.conf ]; then
    # Add Vhost
    sudo tee /etc/apache2/sites-available/100-solr.demacmedia.com.conf <<EOL
<VirtualHost *:8090>
  ProxyPreserveHost On
  ProxyRequests Off
  ServerName solr.demacmedia.com
  ProxyPass / http://127.0.0.1:8080/
  ProxyPassReverse / http://127.0.0.1:8080/
</VirtualHost>
EOL

    # Enable Vhost
    sudo a2ensite 100-solr.demacmedia.com

    # Reload apache
    sudo service apache2 reload
fi

# Setup Solr Script
yes | cp -rf /vagrant/files/solr.sh /usr/local/bin/solr
chmod +x /usr/local/bin/solr