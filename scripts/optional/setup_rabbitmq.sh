#!/usr/bin/env bash
echo "******************************"
echo "*  setup_rabbitmq.sh    *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

# Install RabbitMq

if [ ! -f /etc/rabbitmq/rabbitmq-env.conf ]; then
    apt-get install -y rabbitmq-server
    rabbitmq-plugins enable rabbitmq_management
    echo "[{rabbit, [{loopback_users, []}]}]." >> /etc/rabbitmq/rabbitmq.config
    service rabbitmq-server restart
fi