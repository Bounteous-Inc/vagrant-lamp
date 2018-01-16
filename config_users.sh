#!/usr/bin/env bash

#  For no homeDir use -
#  For no shell   use -
#  For no comment use -
#  Escape any spaces appearing in comments like this - 'MySQL\ Server'

config_users=(
#    'uid  gid  name        homeDir           shell          comment'
     '500  500  mysql       -                 /bin/false     MySQL\ Server'
     '501  501  redis       /var/lib/redis    /bin/false     Redis\ Server'
     '502  501  varnish     /home/varnish     /bin/false     -'
     '503  503  varnishlog  /home/varnishlog  /bin/false     -'
)
