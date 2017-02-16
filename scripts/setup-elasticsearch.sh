#!/usr/bin/env bash

if [ ! -f /etc/elasticsearch/elasticsearch.yml ]; then
    wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.5.2.deb
    dpkg -i elasticsearch-1.5.2.deb
    update-rc.d elasticsearch defaults
fi