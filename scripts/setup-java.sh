#!/usr/bin/env bash

if [ ! -f /usr/bin/java ]; then
    apt-get install -y openjdk-7-jre
fi