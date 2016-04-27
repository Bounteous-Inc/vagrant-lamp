#!/usr/bin/env bash

function show_usage {
cat <<- _EOF_
Sync Remote Database to Local (will prompt for password)

Usage: mysql-sync -i remote-ip -p remote-port -u remote-username -d remote-database
Options:
  -i ip address      : Remote MYSQL IP or URL
  -p port            : Remote MYSQL Port
  -u username        : Remote MYSQL Username
  -d database        : Remote MYSQL database name

_EOF_
exit 1
}

# mysql-sync.sh

# GENERATED USING ecdunbar'S SCRIPT
# Source script at: https://gist.github.com/ecdundar/789660d830d6d40b6c90
function sync_db {
    MYSQLDUMP="/usr/bin/mysqldump"
    MYSQL="/usr/bin/mysql"

    REMOTECONNECTIONSTR="-h ${RemoteIp} -u ${RemoteUsername} --port=${RemotePort} --password=${RemotePassword} "

    LOCALSERVERIP="127.0.0.1"
    LOCALSERVERUSER="root"
    LOCALSERVERPASSWORD="root"
    LOCALCONNECTION="-h ${LOCALSERVERIP} -u ${LOCALSERVERUSER} --password=${LOCALSERVERPASSWORD} "
    DATAONLYTABLES=["core_session" "dataflow_batch" "dataflow_batch_export" "dataflow_batch_import" "dataflow_import_data" "dataflow_session" "log_url" "log_url_info" "log_visitor" "log_visitor_info" "log_visitor_online "]

    IGNOREVIEWS=""
    MYVIEWS=""

    # CREATE NON-EXISTING DATABASES
    echo "create database if not exists $RemoteDatabase; "
    #$MYSQL $LOCALCONNECTION --batch -N -e "drop database $RemoteDatabase; "
    $MYSQL $LOCALCONNECTION --batch -N -e "create database if not exists $RemoteDatabase; " 2>&1 | grep -v "Warning: Using a password"

    # COPY ALL TABLES
    echo "TABLES "$RemoteDatabase
    # GET LIST OF TABLES
    tables=`$MYSQL $REMOTECONNECTIONSTR --batch -N -e "select table_name from information_schema.tables where table_name not like '% %' and table_name not like '%-%' and table_type='BASE TABLE' and table_schema='$RemoteDatabase';" 2>&1 | grep -v "Warning: Using a password"`
    for table in $tables; do
        if [[ $table == "dataflow_"* ]] || [[ $table == "log_"* ]] || [[ $table == *"_cl" ]] ; then
            echo $RemoteDatabase"."$table' - Structure Only'
            $MYSQLDUMP $REMOTECONNECTIONSTR $IGNOREVIEWS -d --compress --quick --create-options --extended-insert --lock-tables=false --skip-add-locks \
            --skip-comments --skip-disable-keys --default-character-set=latin1 --skip-triggers --single-transaction  $RemoteDatabase $table 2>&1 | grep -v "Warning: Using a password" | \
            mysql $LOCALCONNECTION  $RemoteDatabase  2>&1 | grep -v "Warning: Using a password"
        else
            echo $RemoteDatabase"."$table
            $MYSQLDUMP $REMOTECONNECTIONSTR $IGNOREVIEWS --compress --quick --create-options --extended-insert --lock-tables=false --skip-add-locks \
            --skip-comments --skip-disable-keys --default-character-set=latin1 --skip-triggers --single-transaction  $RemoteDatabase $table 2>&1 | grep -v "Warning: Using a password" | \
            mysql $LOCALCONNECTION  $RemoteDatabase  2>&1 | grep -v "Warning: Using a password"
        fi
    done

    # COPY ALL PROCEDURES
    echo "PROCEDURES "$RemoteDatabase
    #PROCEDURES
    $MYSQLDUMP $REMOTECONNECTIONSTR --compress --quick --routines --no-create-info --no-data --no-create-db --skip-opt --skip-triggers $RemoteDatabase 2>&1 | grep -v "Warning: Using a password" | \
    sed -r 's/DEFINER=`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g' | mysql $LOCALCONNECTION  $RemoteDatabase 2>&1 | grep -v "Warning: Using a password"

    # COPY ALL TRIGGERS
    echo "TRIGGERS "$RemoteDatabase
    #TRIGGERS
    $MYSQLDUMP $REMOTECONNECTIONSTR  --compress --quick --no-create-info --no-data --no-create-db --skip-opt --triggers $RemoteDatabase 2>&1 | grep -v "Warning: Using a password" | \
    sed -r 's/DEFINER=`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g' | mysql $LOCALCONNECTION  $RemoteDatabase 2>&1 | grep -v "Warning: Using a password"

    # COPY ALL VIEWS
    # GET LIST OF ITEMS
    views=`$MYSQL $REMOTECONNECTIONSTR --batch -N -e "select table_name from information_schema.tables where table_name not like '% %' and table_name not like '%-%' and table_type='VIEW' and table_schema='$RemoteDatabase';" 2>&1 | grep -v "Warning: Using a password"`
    MYVIEWS=""
    for view in $views; do
        MYVIEWS=${MYVIEWS}" "$view" " 2>&1 | grep -v "Warning: Using a password"
    done
    echo "VIEWS "$RemoteDatabase
    if [ -n "$MYVIEWS" ]; then
      #VIEWS
      $MYSQLDUMP $REMOTECONNECTIONSTR --compress --quick -Q -f --no-data --skip-comments --skip-triggers --skip-opt --no-create-db --complete-insert --add-drop-table $RemoteDatabase $MYVIEWS 2>&1 | grep -v "Warning: Using a password" | \
      sed -r 's/DEFINER=`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g'  | mysql $LOCALCONNECTION  $RemoteDatabase 2>&1 | grep -v "Warning: Using a password"
    fi

    echo   "Done!"
}

#Parse flags
while getopts "h:i:p:u:d:" OPTION; do
    case $OPTION in
        h)
            show_usage
            ;;
        i)
            RemoteIp=$OPTARG
            ;;
        p)
            RemotePort=$OPTARG
            ;;
        u)
            RemoteUsername=$OPTARG
            ;;
        d)
            RemoteDatabase=$OPTARG
            ;;
        *)
            show_usage
            ;;
    esac
done

if [ "$RemoteIp" = "" ] ; then
    echo "Missing Remote DB IP address!!"
	show_usage
fi

if [ "$RemotePort" = "" ] ; then
    echo "Missing Remote DB Port!!"
	show_usage
fi

if [ "$RemoteUsername" = "" ] ; then
    echo "Missing Remote DB Username!!"
	show_usage
fi

if [ "$RemoteDatabase" = "" ] ; then
    echo "Missing Remote DB Database name!! ${RemoteDatabase}"
	show_usage
fi

read -s -p "Enter Remote DB Password: " RemotePassword

if [ "$RemotePassword" = "" ] ; then
    echo "Invalid Password"
	show_usage
fi

mysql --host="${RemoteIp}" --port="${RemotePort}" --user="${RemoteUsername}" --password="${RemotePassword}" --database="${RemoteDatabase}" -e exit 2>/dev/null
dbstatus=`echo $?`

if [ "$dbstatus" -ne 0 ]; then
    echo 'Unable to connect'
else
    echo 'Connection Successful'
fi

sync_db