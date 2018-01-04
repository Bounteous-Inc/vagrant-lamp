#!/usr/bin/env bash
echo "******************************"
echo "* 001-setup_users.sh         *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

groupadd -g 500 mysql
groupadd -g 501 redis
groupadd -g 502 varnish
groupadd -g 503 varnishlog

useradd -u 500 -g 500 -M                  -s /bin/false -c "MySQL Server" mysql
useradd -u 501 -g 501 -d /var/lib/redis   -s /bin/false -c "Redis Server" redis
useradd -u 502 -g 502 -d /home/varnish    -s /bin/false                   varnish
useradd -u 503 -g 503 -d /home/varnishlog -s /bin/false                   varnishlog
 
