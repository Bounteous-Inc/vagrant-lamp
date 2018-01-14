#!/usr/bin/env bash

#  For no homeDir use -
#  For no shell   use -
#  For no comment use -
#  Underscores in comments are replaced with spaces

config_users=(
#    'uid  gid  name        homeDir           shell          comment'
     '500  500  mysql       -                 /bin/false     MySQL_Server'
     '501  501  redis       /var/lib/redis    /bin/false     Redis_Server'
     '502  501  varnish     /home/varnish     /bin/false     -'
     '503  503  varnishlog  /home/varnishlog  /bin/false     -'
)
