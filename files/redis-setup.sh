#!/usr/bin/env bash
#
#   Show Usage, Output to STDERR
#
function show_usage {
cat <<- _EOF_

Usage: redis-setup add|remove|list -n name [-p port] [-s save]
Options:
  -n name            : redis instance name ie. sitename-sessions
  -p port            : redis port number ie. 6380, OPTIONAL
  -s save            : enable saving, OPTIONAL

_EOF_
exit 1
}

function create_redis_conf {
    if [ "$RedisSave" = "" ] ; then
        cat <<- _EOF_
include /etc/redis/redis-default.conf
pidfile /var/run/redis/redis-$RedisName.pid
port $RedisPort
_EOF_
    else
        cat <<- _EOF_
include /etc/redis/redis-default.conf
pidfile /var/run/redis/redis-$RedisName.pid
port $RedisPort
save 900 1
save 300 10
save 60 10000
dbfilename redis-$RedisName.rdb
_EOF_
    fi
}

function create_redis_init {
    cat <<- _EOF_
#! /bin/sh
### BEGIN INIT INFO
# Provides:             redis-server
# Required-Start:       $syslog $remote_fs
# Required-Stop:        $syslog $remote_fs
# Should-Start:         $local_fs
# Should-Stop:          $local_fs
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    redis-server - Persistent key-value db
# Description:          redis-server - Persistent key-value db
### END INIT INFO


PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/redis-server
DAEMON_ARGS=/etc/redis/redis-${RedisName}.conf
NAME=redis-${RedisName}
DESC=redis-${RedisName}

RUNDIR=/var/run/redis
PIDFILE=\$RUNDIR/redis-${RedisName}.pid

test -x \$DAEMON || exit 0

if [ -r /etc/default/\$NAME ]
then
        . /etc/default/\$NAME
fi

. /lib/lsb/init-functions

set -e

case "\$1" in
  start)
        echo -n "Starting \$DESC: "
        mkdir -p \$RUNDIR
        touch \$PIDFILE
        chown redis:redis \$RUNDIR \$PIDFILE
        chmod 755 \$RUNDIR

        if [ -n "\$ULIMIT" ]
        then
                ulimit -n \$ULIMIT
        fi

        if start-stop-daemon --start --quiet --umask 007 --pidfile \$PIDFILE --chuid redis:redis --exec \$DAEMON -- \$DAEMON_ARGS
        then
                echo "\$NAME."
        else
                echo "failed"
        fi
        ;;
  stop)
        echo -n "Stopping \$DESC: "
        if start-stop-daemon --stop --retry forever/TERM/1 --quiet --oknodo --pidfile \$PIDFILE --exec \$DAEMON
        then
                echo "\$NAME."
        else
                echo "failed"
        fi
        rm -f \$PIDFILE
        sleep 1
        ;;

  restart|force-reload)
        \${0} stop
        \${0} start
        ;;

  status)
        echo -n "\$DESC is "
        if start-stop-daemon --stop --quiet --signal 0 --name \${NAME} --pidfile \${PIDFILE}
        then
                echo "running"
        else
                echo "not running"
                exit 1
        fi
        ;;

  *)
        echo "Usage: /etc/init.d/\$NAME {start|stop|restart|force-reload|status}" >&2
        exit 1
        ;;
esac

exit 0


}
_EOF_
}

function confirm () {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case ${response} in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

function list_redis_instances {
    IFS=""
	RedisFiles=($(grep -Hs '^port ' ${RedisPath}redis*.conf))
	if [ "$RedisFiles" = "" ] ; then
        echo "No Redis Instances found!!"
        exit 1
    fi
	for el in "${RedisFiles[@]}" ; do
	    el="${el//'/etc/redis/'/}"
		echo "${el//'.conf:port'/' : Port'}"
	done
}

function add_redis_instance {
    if [ -f "$RedisPath$RedisPrefix$RedisName.conf" ]; then
        echo "Redis instance with Name '$RedisName' already exists."
        exit 1
    fi
    if [ "$RedisPort" = "" ] ; then
        get_next_port
    fi
    check_redis_ports
    create_redis_conf >> ${RedisPath}${RedisPrefix}${RedisName}.conf
    create_redis_init >> /etc/init.d/${RedisPrefix}${RedisName}
    chmod +x /etc/init.d/${RedisPrefix}${RedisName}
    /etc/init.d/${RedisPrefix}${RedisName} start
    echo "Created and Started Redis Instance: $RedisName, on port $RedisPort"
    exit 1
}

function remove_redis_instance {
    if [ ! -f "$RedisPath$RedisPrefix$RedisName.conf" ]; then
        echo "Unable able to find redis instance: $RedisName"
        exit 1
    fi
    if [ -f "/etc/init.d/${RedisPrefix}${RedisName}" ]; then
        /etc/init.d/${RedisPrefix}${RedisName} stop
        rm /etc/init.d/${RedisPrefix}${RedisName}
    fi
    rm "$RedisPath$RedisPrefix$RedisName.conf"
    echo "Removed Redis Instance: $RedisName"
    exit 1
}

function check_redis_ports {
    IFS=""
	RedisFiles=($(grep -s "^port $RedisPort" ${RedisPath}redis*.conf))
	if [ "$RedisFiles" != "" ] ; then
        echo "Port $RedisPort is already in use"
        list_redis_instances
        exit 1
    fi
}

function get_next_port {
	RedisFiles=($(grep -hs "^port " ${RedisPath}redis*.conf))
	if [ "$RedisFiles" = "" ] ; then
        RedisPort="6380"
    fi

    # Cast Found ports to array
    PortArray=( $(
    for el in "${RedisFiles[@]}";  do
        echo "${el//'port'/}"
    done) )

    PortArraySorted=( $(
    for el in "${PortArray[@]}";  do
        echo "$el"
    done | sort) )

    RedisPort=$((${PortArraySorted[-1]}+1))
}

RedisPath="/etc/redis/"
RedisPrefix="redis-"

# Transform long options to short ones
for arg in "$@"; do
  case "$arg" in
    "add")
        shift
        set -- "$@" "-a"
        ;;
    "remove")
        shift
        set -- "$@" "-r"
        ;;
    "list")
        shift
        set -- "$@" "-l"
        ;;
     *)
        set -- "$@" "$arg"
  esac
done

#Parse flags
while getopts "h:n:p:salr" OPTION; do
    case $OPTION in
        h)
            show_usage
            ;;
        n)
            RedisName=$OPTARG
            ;;
        p)
            RedisPort=$OPTARG
        ;;
        s)
            RedisSave='yes'
            ;;
        a)
            Task='add'
            ;;
        r)
            Task='remove'
            ;;
        l)
            Task='list'
            ;;
        *)
            show_usage
            ;;
    esac
done

if [ "$Task" = "add" ] ; then
	if [ "$RedisName" = "" ] ; then
        echo "Missing Redis instance name!!"
		show_usage
    fi
    add_redis_instance
elif [ "$Task" = "list" ] ; then
	list_redis_instances
elif [ "$Task" = "remove" ] ; then
    if [ "$RedisName" = "" ] ; then
        echo "Missing Redis instance name!! $RedisName "
		show_usage
    fi
    confirm "Remove Redis instance $RedisName? [y/N]" && remove_redis_instance
else
	show_usage
fi
