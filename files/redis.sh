#!/usr/bin/env bash
#
#   Show Usage, Output to STDERR
#
function show_usage {
cat <<- _EOF_

Usage: redis add|remove|list -n name [-p port] [-s save]
Options:
  -n name            : redis instance name ie. sitename-sessions
  -p port            : redis port number ie. 6380, OPTIONAL
  -s save            : enable saving (allow cache to persist between restarts), OPTIONAL

_EOF_
exit 1
}

function create_redis_conf {
    if [ "$redisSave" = "" ] ; then
        cat <<- _EOF_
include /etc/redis/redis-default.conf
pidfile /var/run/redis/redis-$redisName.pid
port $redisPort
_EOF_
    else
        cat <<- _EOF_
include /etc/redis/redis-default.conf
pidfile /var/run/redis/redis-$redisName.pid
port $redisPort
save 900 1
save 300 10
save 60 10000
dbfilename redis-$redisName.rdb
_EOF_
    fi
}

function create_redis_init {
    cat <<- _EOF_
#! /bin/sh
### BEGIN INIT INFO
# Provides:		redis-server-${redisName}
# Required-Start:	$syslog $remote_fs
# Required-Stop:	$syslog $remote_fs
# Should-Start:		$local_fs
# Should-Stop:		$local_fs
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:	redis-server - Persistent key-value db
# Description:		redis-server - Persistent key-value db
### END INIT INFO


PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/redis-server
DAEMON_ARGS=/etc/redis/redis-${redisName}.conf
NAME=redis-${redisName}
DESC=redis-${redisName}

RUNDIR=/var/run/redis
PIDFILE=$RUNDIR/redis-${redisName}.pid

test -x $DAEMON || exit 0

if [ -r /etc/default/$NAME ]
then
	. /etc/default/$NAME
fi

. /lib/lsb/init-functions

set -e

Run_parts () {
	if [ -d /etc/redis/\${NAME}.\${1}.d ]
	then
		su redis -s /bin/sh -c "run-parts --exit-on-error /etc/redis/\${NAME}.\${1}.d"
	fi
}

case "$1" in
  start)
	echo -n "Starting $DESC: "
	mkdir -p $RUNDIR
	touch $PIDFILE
	chown redis:redis $RUNDIR $PIDFILE
	chmod 755 $RUNDIR

	if [ -n "$ULIMIT" ]
	then
		ulimit -n $ULIMIT
	fi

	Run_parts pre-up

	if start-stop-daemon --start --quiet --oknodo --umask 007 --pidfile $PIDFILE --chuid redis:redis --exec $DAEMON -- $DAEMON_ARGS
	then
		Run_parts post-up
		echo "$NAME."
	else
		echo "failed"
	fi
	;;
  stop)
	echo -n "Stopping $DESC: "

	Run_parts pre-down

	if start-stop-daemon --stop --retry forever/TERM/1 --quiet --oknodo --pidfile $PIDFILE --exec $DAEMON
	then
		Run_parts post-down
		echo "$NAME."
	else
		echo "failed"
	fi
	rm -f $PIDFILE
	sleep 1
	;;

  restart|force-reload)
	\${0} stop
	\${0} start
	;;

  status)
	status_of_proc -p \${PIDFILE} \${DAEMON} \${NAME}
	;;

  *)
	echo "Usage: /etc/init.d/$NAME {start|stop|restart|force-reload|status}" >&2
	exit 1
	;;
esac

exit 0

_EOF_
}

function create_redis_service {
    cat <<- _EOF_
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
Type=forking
PIDFile=/var/run/redis/redis-${redisName}.pid
User=redis
Group=redis
ExecStart=/usr/bin/redis-server /etc/redis/redis-${redisName}.conf
ExecStop=/usr/bin/redis-cli shutdown
Restart=always

[Install]
WantedBy=multi-user.target
_EOF_
}

function show_header {
    echo -e "\e[32m"
    echo -e "******************************"
    echo -e "* Redis script version 1.0.1 *"
    echo -e "******************************\e[0m"
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

function show_error {
    show_header
    echo -e "\e[31m${1}\e[0m"
}

function show_success {
    show_header
    echo -e "\e[32m${1}\e[0m"
}

function show_notice {
    echo -e "\e[33m${1}\e[0m"
}

function check_permissions {
    if [ "$(id -u)" != "0" ] ; then
        show_error "Command \e[1mredis add|remove \e[0;31mmust be run with 'sudo' or as root.  Aborting."
        exit 1
    fi
}

function check_redis_name {
    if [ "$redisName" = "" ] ; then
        show_error "Missing Redis instance name!!"
		show_usage
    fi
}

function list_redis_instances {
    IFS=""
	redisFiles=($(grep -Hs '^port ' ${redisPath}redis*.conf))
	if [ "$redisFiles" = "" ] ; then
        show_error "No Redis instances found!!"
        exit 1
    fi

    if [ "$1" == "" ]; then
        show_header
    fi

	for el in "${redisFiles[@]}" ; do
	    el="${el//'/etc/redis/'/}"
		echo "${el//'.conf:port'/' : Port'}"
	done
}

function add_redis_instance {
    if [ -f "$redisPath$redisPrefix$redisName.conf" ]; then
        show_error "Redis instance with name '$redisName' already exists."
        exit 1
    fi

    if [ "$redisPort" = "" ] ; then
        get_next_port
        show_notice "No redis port passed, using port $redisPort"
    fi

    check_redis_ports
    create_redis_conf >> ${redisPath}${redisPrefix}${redisName}.conf
    create_redis_init >> /etc/init.d/${redisPrefix}${redisName}
    create_redis_service >> /etc/systemd/system/${redisPrefix}${redisName}.service
    chmod +x /etc/init.d/${redisPrefix}${redisName}
    systemctl enable ${redisPrefix}${redisName}
    systemctl start ${redisPrefix}${redisName}

    show_success "Created and started Redis instance $redisName on port $redisPort"
    show_notice "You can now modify your Magento local.xml or env.php to use this Redis instance."
    show_notice "It is recommended to use the following settings:"
    show_notice "Redis Server Hostname:\e[0m 127.0.0.1"
    show_notice "Redis Server Port:\e[0m $redisPort"
    show_notice "Redis Server Database (for sessions):\e[0m 0"
    show_notice "Redis Server Database (for cache):\e[0m 1"
    show_notice "Redis Server Database (for page_cache):\e[0m 2"
    exit 1
}

function remove_redis_instance {
    if [ ! -f "$redisPath$redisPrefix$redisName.conf" ]; then
        show_error "Unable able to find Redis instance $redisName"
        list_redis_instances false
        exit 1
    fi

    if [ -f "/etc/init.d/${redisPrefix}${redisName}" ]; then
        /etc/init.d/${redisPrefix}${redisName} stop
        rm /etc/init.d/${redisPrefix}${redisName}
        rm /etc/systemd/system/${redisPrefix}${redisName}.service
    fi
    rm "$redisPath$redisPrefix$redisName.conf"

    show_success "Removed Redis instance $redisName"
    list_redis_instances false
    exit 1
}

function check_redis_ports {
    IFS=""
	redisFiles=($(grep -s "^port $redisPort" ${redisPath}redis*.conf))
	if [ "$redisFiles" != "" ] ; then
        show_error "Port $redisPort is already in use"
        list_redis_instances false
        exit 1
    fi
}

function get_next_port {
	redisFiles=($(grep -hs "^port " ${redisPath}redis*.conf))
	if [ "$redisFiles" = "" ] ; then
        redisPort="6380"
    fi

    # Cast Found ports to array
    PortArray=( $(
    for el in "${redisFiles[@]}";  do
        echo "${el//'port'/}"
    done) )

    PortArraySorted=( $(
    for el in "${PortArray[@]}";  do
        echo "$el"
    done | sort) )

    redisPort=$((${PortArraySorted[-1]}+1))
}

# Set Defaults
redisPath="/etc/redis/"
redisPrefix="redis-"

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
            redisName=$OPTARG
            ;;
        p)
            redisPort=$OPTARG
        ;;
        s)
            redisSave='yes'
            ;;
        a)
            task='add'
            ;;
        r)
            task='remove'
            ;;
        l)
            task='list'
            ;;
        *)
            show_usage
            ;;
    esac
done

case ${task} in
    list)
        list_redis_instances
        ;;
    add)
        check_permissions
        check_redis_name
        add_redis_instance
        ;;
    remove)
        check_permissions
        check_redis_name
        confirm "Remove Redis instance $redisName? [y/N]" && remove_redis_instance
        ;;
    *)
        show_header
        show_usage
        ;;
esac