#!/usr/bin/env bash

# Restart Services
service apache2 restart
service varnish restart
source /etc/profile.d/00-aliases.sh
phpRestart
