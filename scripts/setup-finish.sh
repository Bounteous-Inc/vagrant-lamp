#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

# Restart Services
service apache2 restart
service varnish restart
service php-5.6 restart
service php-7   restart
service php-7.1 restart
