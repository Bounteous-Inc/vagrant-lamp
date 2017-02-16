#!/usr/bin/env bash

#
#   Show Usage, Output to STDERR
#
function show_usage {
cat <<- _EOF_

Create or Remove vHost in Ubuntu Server
Assumes /etc/apache2/sites-available and /etc/apache2/sites-enabled setup are used

Usage: vhost add|remove -d DocumentRoot -n ServerName [-a ServerAlias] [-s CertPath] [-c CertName]
Options:
  -d DocumentRoot    : DocumentRoot i.e. /var/www/yoursite
  -h Help            : Show this menu.
  -n ServerName      : Domain i.e. example.com or sub.example.com or 'js.example.com static.example.com'
  -a ServerAlias     : Alias i.e. *.example.com or another domain altogether OPTIONAL
  -s CertPAth        : File path to the SSL certificate. Directories only, no file name. OPTIONAL
                       If using an SSL Certificate, also creates a port :443 vhost as well.
                       This *ASSUMES* a .crt and a .key file exists
                       at file path /provided-file-path/your-server-or-cert-name.[crt|key].
                       Otherwise you can except Apache errors when you reload Apache.
                       Ensure Apache's mod_ssl is enabled via "sudo a2enmod ssl".
  -c CertName        : Certificate Name "example.com" becomes "example.com.key" and "example.com.crt". OPTIONAL

_EOF_
exit 1
}

#
#   Output vHost skeleton, fill with userinput
#   To be outputted into new file
#
function create_vhost {
cat <<- _EOF_
<VirtualHost *:8090>
    ServerAdmin webmaster@localhost
    ServerName $ServerName
    $ServerAlias

    RailsEnv development
    DocumentRoot $DocumentRoot

    <Directory $DocumentRoot>
       Require all granted
	    Options FollowSymLinks
	    # This relaxes Apache security settings.
	    AllowOverride None
	    # MultiViews must be turned off.
	    Order allow,deny
	    Allow from all
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$ServerName-error.log

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel warn

    CustomLog \${APACHE_LOG_DIR}/$ServerName-access.log combined


</VirtualHost>
_EOF_
}

function create_ssl_vhost {
cat <<- _EOF_
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    ServerName $ServerName
    $ServerAlias

    RailsEnv development
    DocumentRoot $DocumentRoot

    <Directory $DocumentRoot>
        Require all granted
	    Options FollowSymLinks
	    # This relaxes Apache security settings.
	    AllowOverride None
	    # MultiViews must be turned off.
	    Order allow,deny
	    Allow from all
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$ServerName-error.log

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel warn

    CustomLog \${APACHE_LOG_DIR}/$ServerName-access.log combined

    SSLEngine on

    SSLCertificateFile  $CertPath/$CertName.crt
    SSLCertificateKeyFile $CertPath/$CertName.key

    BrowserMatch "MSIE [2-6]" \\
        nokeepalive ssl-unclean-shutdown \\
        downgrade-1.0 force-response-1.0
    # MSIE 7 and newer should be able to use keepalive
    BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
</VirtualHost>
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

function add_vhost {

    # If alias is set:
    if [ "$Alias" != "" ]; then
        ServerAlias="ServerAlias "$Alias
    fi

    # If CertName doesn't get set, set it to ServerName
    if [ "$CertName" == "" ]; then
        CertName=$ServerName
    fi

    if [ ! -d $DocumentRoot ]; then
        mkdir -p $DocumentRoot
        #chown USER:USER $DocumentRoot #POSSIBLE IMPLEMENTATION, new flag -u ?
    fi

    create_vhost > /etc/apache2/sites-available/${ServerName}.conf

    # Add :443 handling
    if [ "$CertPath" != "" ]; then
        create_ssl_vhost >> /etc/apache2/sites-available/${ServerName}.conf
    fi

    # Enable Site
    cd /etc/apache2/sites-available/ && a2ensite ${ServerName}.conf

    # Add entry to hosts
    if ! grep -q "127.0.0.1 $ServerName" /etc/hosts ; then
      echo "127.0.0.1 $ServerName" >> /etc/hosts
    fi
    service apache2 reload
}

function remove_vhost {
    if [ ! -f "/etc/apache2/sites-available/$ServerName.conf" ]; then
        echo "vHost $ServerName not found. Aborting"
        show_usage
    fi
    if [ -f "/etc/apache2/sites-enabled/$ServerName.conf" ]; then
        cd /etc/apache2/sites-available/ && a2dissite ${ServerName}.conf
    fi
    rm /etc/apache2/sites-available/${ServerName}.conf
    service apache2 reload
}

# Set Defaults
CertPath=""
ServerAlias=""

# Transform long options to short ones
for arg in "$@"; do
  case "$arg" in
    "add")
        shift
        set -- "$@" "-A"
        ;;
    "remove")
        shift
        set -- "$@" "-R"
        ;;
     *)
        set -- "$@" "$arg"
  esac
done

#Parse flags
while getopts "d:s:a:n:c:h:AR" OPTION; do
    case $OPTION in
        h)
            show_usage
            ;;
        d)
            DocumentRoot=$OPTARG
            ;;
        n)
            ServerName=$OPTARG
            ;;
        a)
            Alias=$OPTARG
            ;;
        s)
            CertPath=$OPTARG
            ;;
        c)
            CertName=$OPTARG
            ;;
        A)
            Task="add"
            ;;
        R)
            Task="remove"
            ;;
        *)
            show_usage
            ;;
    esac
done

if [ "$Task" = "add" ] ; then
	if [ "$ServerName" = "" ] ; then
        echo "Missing Server Name!! Aborting "
		show_usage
    elif [ "$DocumentRoot" == "" ]; then
        echo 'DocumentRoot must be set!! Aborting'
        show_usage
    elif [ -f "/etc/apache2/sites-available/$ServerName.conf" ]; then
        if confirm "vHost $ServerName already exists. Remove and Recreate? [y/N]" ; then
            remove_vhost
        else
            exit 1
        fi
    fi
    add_vhost
elif [ "$Task" = "remove" ] ; then
    if [ "$ServerName" = "" ] ; then
        echo "Missing Server Name!! Aborting "
		show_usage
    fi
    confirm "Remove vHost $ServerName? [y/N]" && remove_vhost
else
	show_usage
fi