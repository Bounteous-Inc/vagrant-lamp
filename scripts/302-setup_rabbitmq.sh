#!/usr/bin/env bash
echo "******************************"
echo "*     setup_rabbitmq.sh      *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

# Install RabbitMq

if [ ! -f /etc/rabbitmq/rabbitmq-env.conf ]; then
    apt-get install -y rabbitmq-server 2>&1
    rabbitmq-plugins enable rabbitmq_management
    echo "[{rabbit, [{loopback_users, []}]}]." >> /etc/rabbitmq/rabbitmq.config
    service rabbitmq-server restart
fi

if [ ! -f /etc/apache2/sites-available/100-rabbitmq.demacmedia.com.conf ]; then
    # Add Vhost
    sudo tee /etc/apache2/sites-available/100-rabbitmq.demacmedia.com.conf <<EOL
<VirtualHost *:8090>
  ProxyPreserveHost On
  ProxyRequests Off
  ServerName rabbitmq.demacmedia.com
  ProxyPass / http://127.0.0.1:15672/
  ProxyPassReverse / http://127.0.0.1:15672/
</VirtualHost>
EOL

    # Enable Vhost
    sudo a2ensite 100-rabbitmq.demacmedia.com

    # Reload apache
    sudo service apache2 reload
fi