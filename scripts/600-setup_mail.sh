#!/usr/bin/env bash
echo "******************************"
echo "* 600-setup_mail.sh          *"
echo "******************************"

# Download binary from github
if [ ! -f /usr/local/bin/mailhog ]; then
    wget --quiet -O /usr/local/bin/mailhog https://github.com/mailhog/MailHog/releases/download/v0.2.0/MailHog_linux_amd64

    # Make it executable
    chmod +x /usr/local/bin/mailhog
fi

if [ ! -f /usr/local/bin/mhsendmail ]; then
    wget --quiet -O /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64
    chmod +x /usr/local/bin/mhsendmail
fi

for i in /opt/phpfarm/inst/*/lib/php.ini
do
    if ! grep -q "mhsendmail" $i; then
        echo >> $i
        echo "sendmail_path = /usr/local/bin/mhsendmail" >> $i
    fi
done


if [ ! -f /usr/local/bin/mailhog ]; then
    # Make it start on reboot
    sudo tee /etc/init/mailhog.conf <<EOL
description "Mailhog"
start on runlevel [2345]
stop on runlevel [!2345]
respawn
pre-start script
    exec su - vagrant -c "/usr/bin/env /usr/local/bin/mailhog > /dev/null 2>&1 &"
end script
EOL

    # Start it now in the background
    sudo service mailhog start
fi

if [ ! -f /etc/apache2/sites-available/mailhog.demacmedia.com.conf ]; then
    # Add Vhost
    sudo tee /etc/apache2/sites-available/mailhog.demacmedia.com.conf <<EOL
<VirtualHost *:8090>
  ProxyPreserveHost On
  ProxyRequests Off
  ServerName mailhog.demacmedia.com
  ProxyPass / http://192.168.33.10:8025/
  ProxyPassReverse / http://192.168.33.10:8025/
</VirtualHost>
EOL

    # Enable Vhost
    sudo a2ensite mailhog.demacmedia.com

    # Reload apache
    sudo service apache2 reload
fi
