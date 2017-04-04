#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

# Restart Services
service apache2 restart
service varnish restart
service elasticsearch restart