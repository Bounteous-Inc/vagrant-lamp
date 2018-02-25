#!/usr/bin/env bash
echo "******************************"
echo "* 300-setup_redis.sh         *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

# Setup Redis
apt-get install -y redis-server 2>&1

#setup redis script
yes | cp -rf /vagrant/files/redis.sh /usr/local/bin/redis
chmod +x /usr/local/bin/redis

if [ ! -f /etc/redis/redis-default.conf ]; then
    cp /vagrant/files/redis-default.conf /etc/redis/redis-default.conf
fi
