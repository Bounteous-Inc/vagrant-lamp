#!/usr/bin/env bash
echo "******************************"
echo "* 001-setup_users.sh         *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

# Create groups:
if [ ! $(getent group mysql) ]; then
    groupadd -g 500 mysql
fi
if [ ! $(getent group redis) ]; then
    groupadd -g 501 redis
fi
if [ ! $(getent group varnish) ]; then
    groupadd -g 502 varnish
fi
if [ ! $(getent group varnishlog) ]; then
    groupadd -g 503 varnishlog
fi

# Create users
if [ ! $(getent passwd mysql) ]; then
    useradd -u 500 -g 500 -M                  -s /bin/false -c "MySQL Server" mysql
fi
if [ ! $(getent passwd redis) ]; then
    useradd -u 501 -g 501 -d /var/lib/redis   -s /bin/false -c "Redis Server" redis
fi
if [ ! $(getent passwd varnish) ]; then
    useradd -u 502 -g 502 -d /home/varnish    -s /bin/false                   varnish
fi
if [ ! $(getent passwd varnishlog) ]; then
    useradd -u 503 -g 503 -d /home/varnishlog -s /bin/false                   varnishlog
fi
