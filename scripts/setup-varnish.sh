#!/usr/bin/env bash

# Setup Varnish
apt-get install -y varnish
sed -i.bak 's/.port = "8080";$/.port = "8090";/' /etc/varnish/default.vcl
#sed -i.bak 's/Listen 80$/Listen 8090/' /etc/apache2/ports.conf

if [ ! -f /etc/default/varnish.bak ]; then
    cp /etc/default/{varnish,varnish.bak}
fi
cat > /etc/default/varnish <<EOF
START=yes
NFILES=131072
MEMLOCK=82000
DAEMON_OPTS="-a :80 \\
             -T localhost:6082 \\
             -f /etc/varnish/default.vcl \\
             -S /etc/varnish/secret \\
             -s malloc,256m"
EOF