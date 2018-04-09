#!/usr/bin/env bash
echo "******************************"
echo "*  setup_elasticsearch.sh    *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

# Install the require Java
apt-get install -y openjdk-8-jre-headless 2>&1

# Install ElasticSearch

if [ ! -f /etc/elasticsearch/elasticsearch.yml ]; then
    cd /tmp
    wget --progress=bar:force https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-2.4.6.deb
    dpkg -i elasticsearch-2.4.6.deb

    # Start on boot
    sudo systemctl enable elasticsearch.service
    service elasticsearch start
fi

if [ $(grep -c "index.query.bool.max_clause_count" /etc/elasticsearch/elasticsearch.yml ) -eq 0 ] ; then
    echo "index.query.bool.max_clause_count: 10024" >> /etc/elasticsearch/elasticsearch.yml
    service elasticsearch restart
fi
