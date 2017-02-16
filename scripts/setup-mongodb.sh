#!/usr/bin/env bash
/usr/bin/mongo
if [ ! -f /usr/bin/mongo ]; then
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
    echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list

    apt-get update

    apt-get install -y mongodb-org

    # Allow external Access
    sed -i.bak 's/  bindIp: 127.0.0.1$/ #bindIp: 127.0.0.1/' /etc/mongod.conf
fi