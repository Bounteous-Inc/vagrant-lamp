#!/usr/bin/env bash

# Setup Redis
apt-get install -y redis-server

#setup redis script
yes | cp -rf /vagrant/files/redis-setup.sh /usr/local/bin/redis-setup
chmod +x /usr/local/bin/redis-setup

if [ ! -f /etc/redis/redis-default.conf ]; then
    cp /vagrant/files/redis-default.conf /etc/redis/redis-default.conf
fi