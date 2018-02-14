#!/usr/bin/env bash
echo "******************************"
echo "* 999-setup_finish.sh        *"
echo "******************************"

# Restart Services
service apache2 restart
service varnish restart
source /etc/profile.d/*-aliases.sh
phpRestart
