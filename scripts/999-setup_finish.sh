#!/usr/bin/env bash
echo "******************************"
echo "* 999-setup_finish.sh        *"
echo "******************************"

# Restart Services
service apache2 restart
service varnish restart
for f in /etc/profile.d/*-aliases.sh; do source $f; done
phpRestart
