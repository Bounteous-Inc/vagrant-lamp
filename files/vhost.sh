#!/usr/bin/env bash
function show_header {
    echo -e "\e[32m"
    echo -e "***********************"
    echo -e "* vhost version 1.0.3 *"
    echo -e "***********************\e[0m"
}

function show_usage {
    local help
    local _versions=$(get_php_versions)

    read -r -d '' help << EOF_HELP
Create or Remove vHost in Ubuntu Server
Assumes PHP-FPM with proxy_fcgi and /etc/apache2/sites-available and /etc/apache2/sites-enabled setup are used

Usage: sudo vhost add|remove|list|sites -d DocumentRoot -n ServerName [-p PhpVersion] [-a ServerAlias] [-s CertPath] [-c CertName] [-f]
Options:
  -d DocumentRoot    : DocumentRoot i.e. /var/www/yoursite
  -h Help            : Show this menu.
  -n ServerName      : Domain i.e. example.com or sub.example.com or 'js.example.com static.example.com'
  -a ServerAlias     : Alias i.e. *.example.com or another domain altogether OPTIONAL
                       You can now add multiple aliases for any given site, e.g.
                       -a www.example.com -a example.ca -a www.example.ca
  -p PHPVersion      : PHP Version:
                       Optional - to add PHP-FPM proxy support, choose one of these:  [###php_versions###]
  -s CertPath        : ***SELF SIGNED CERTIFICATE ARE AUTOMATICALLY CREATED FOR EACH VHOST USE THIS TO OVERRIDE***
                       File path to the SSL certificate. Directories only, no file name. OPTIONAL
                       If using an SSL Certificate, also creates a port :443 vhost as well.
                       This *ASSUMES* a .crt and a .key file exists
                       at file path /provided-file-path/your-server-or-cert-name.[crt|key].
                       Otherwise you can except Apache errors when you reload Apache.
                       Ensure Apache's mod_ssl is enabled via "sudo a2enmod ssl".
  -k KeyPath         : ***SELF SIGNED CERTIFICATE ARE AUTOMATICALLY CREATED FOR EACH VHOST USE THIS TO OVERRIDE***
                       File path to the SSL Key. Directories only, no file name. OPTIONAL
                       If using an SSL Certificate, also creates a port :443 vhost as well.
                       This *ASSUMES* a .crt and a .key file exists
                       at file path /provided-file-path/your-server-or-cert-name.[crt|key].
                       Otherwise you can except Apache errors when you reload Apache.
                       Ensure Apache's mod_ssl is enabled via "sudo a2enmod ssl".
  -c CertName        : ***SELF SIGNED CERTIFICATE ARE AUTOMATICALLY CREATED FOR EACH VHOST USE THIS TO OVERRIDE***
                       Certificate Name "example.com" becomes "example.com.key" and "example.com.crt". OPTIONAL
                       Will default to ServerName
  -f                 : Force mode - silently reponds 'yes' to any confirmation messages




EOF_HELP
    echo "$help" | sed "s/###php_versions###/${_versions}/g"
    echo ""
}


function get_php_versions {
    local config_php
    source /vagrant/config_php.sh
    for i in "${config_php[@]}"; do
        arr=(${i// / })
        phpn=${arr[1]}
        _versions="${_versions}${phpn} "
    done;
    echo "${_versions:0:-1}"
}


#
#   Output vHost skeleton, fill with userinput
#   To be outputted into new file
#
function create_vhost {
cat <<- _EOF_
<VirtualHost *:8090>
    ServerAdmin webmaster@localhost
    ServerName  $ServerName
    DocumentRoot $DocumentRoot###ServerAlias######PhpProxy###

    # Directory Permissions
    <Directory $DocumentRoot>
        Options +Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    # Logging
    ErrorLog  \${APACHE_LOG_DIR}/$ServerName-error.log
    CustomLog \${APACHE_LOG_DIR}/$ServerName-access.log combined
    LogLevel  warn

</VirtualHost>
_EOF_
}

function create_ssl_vhost {
cat <<- _EOF_

<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    ServerName  $ServerName
    DocumentRoot $DocumentRoot###ServerAlias######PhpProxy###

    # Directory Permissions
    <Directory $DocumentRoot>
        Options +Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    # Logging
    ErrorLog  \${APACHE_LOG_DIR}/$ServerName-error.log
    CustomLog \${APACHE_LOG_DIR}/$ServerName-access.log combined
    LogLevel  warn

    # SSL settings
    SSLEngine on
    SSLCertificateFile  $CertPath/$CertName.crt
    SSLCertificateKeyFile $KeyPath/$CertName.key

    <FilesMatch "\.(cgi|shtml|phtml|php)$">
        SSLOptions +StdEnvVars
    </FilesMatch>

    BrowserMatch "MSIE [2-6]" \\
        nokeepalive ssl-unclean-shutdown \\
        downgrade-1.0 force-response-1.0

    # MSIE 7-19 should be able to use keepalive  (17-9 is NOT a typo)
    BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown

</VirtualHost>
_EOF_
}

function confirm () {
    if [ "$Force" = "y" ]; then
        true
    else
        # call with a prompt string or use a default
        echo -en "\n\e[33m${1:-Are you sure? [y/N]}\e[0m"
        read -r -p ' ' response
        case ${response} in
            [yY][eE][sS]|[yY])
                true
                ;;
            *)
                false
                ;;
        esac
    fi
}

function add_vhost {
    local PhpProxy=''

    # If CertName doesn't get set, set it to ServerName
    if [ "$CertName" == "" ]; then
        CertName=$ServerName
    fi

    # If CertName doesn't get set, set it to ServerName
    if [ "$CertPath" == "" ]; then
        CertPath="/etc/apache2/ssl/cert"
    fi

    # If CertName doesn't get set, set it to ServerName
    if [ "$KeyPath" == "" ]; then
        KeyPath="/etc/apache2/ssl/private"
    fi

    if [ ! -d $DocumentRoot ]; then
        mkdir -p $DocumentRoot
        #chown USER:USER $DocumentRoot #POSSIBLE IMPLEMENTATION, new flag -u ?
    fi

    if [ "${ServerAlias}" != "" ]; then
        ServerAlias="\n    ${ServerAlias}"
    fi

    if [ "${PhpPort}" != "" ]; then
        PhpProxy="\n\n    # PHP proxy specifications\n    <Proxy fcgi:\/\/127.0.0.1:$PhpPort>\n        ProxySet timeout=1800\n    <\/Proxy>\n\n    ProxyPassMatch ^\/(.*\\\.php(\/.*)?)$ fcgi:\/\/127.0.0.1:$PhpPort${DocumentRoot}\/\$1"
    fi

    create_vhost | sed "s|###ServerAlias###|${ServerAlias}|g" | sed "s|###PhpProxy###|${PhpProxy}|g" > /etc/apache2/sites-available/200-${ServerName}.conf

    # Make directory to place SSL Certificate if it doesn't exists
    if [[ ! -d $KeyPath ]]; then
      sudo mkdir -p $KeyPath
    fi

    if [[ ! -d $CertPath ]]; then
      sudo mkdir -p $CertPath
    fi

    if [ ! -f "$CertPath/$ServerName.crt" ] && [ ! -f "$KeyPath/$ServerName.key" ]; then
        openssl req -x509 -nodes -newkey rsa:2048 -keyout "$KeyPath/$ServerName.key" -out "$CertPath/$ServerName.crt" -days 365 \
        -reqexts SAN -extensions SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:$ServerName")) \
        -subj "/C=CA/ST=Ontario/L=Toronto/O=Demac Media/OU=Development/CN=$ServerName"
    elif [ -f "$CertPath/$ServerName.crt" ] && [ -f "$KeyPath/$ServerName.key" ]; then
        if confirm "SSL Key and certificate for $ServerName already exist. Recreate them? [y/N]" ; then
            openssl req -x509 -nodes -newkey rsa:2048 -keyout "$KeyPath/$ServerName.key" -out "$CertPath/$ServerName.crt" -days 365 \
            -reqexts SAN -extensions SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:$ServerName")) \
            -subj "/C=CA/ST=Ontario/L=Toronto/O=Demac Media/OU=Development/CN=$ServerName"
        fi
    fi

    create_ssl_vhost | sed "s|###ServerAlias###|${ServerAlias}|g" | sed "s|###PhpProxy###|${PhpProxy}|g" >> /etc/apache2/sites-available/200-${ServerName}.conf

    # Enable Site
    cd /etc/apache2/sites-available/ && a2ensite 200-${ServerName}.conf

    # Add entry to hosts
    if ! grep -q "127.0.0.1 $ServerName" /etc/hosts ; then
      echo "127.0.0.1 $ServerName" >> /etc/hosts
    fi

    echo ""
    service apache2 reload
}

function remove_vhost {
    if [ ! -f "/etc/apache2/sites-available/$ServerName.conf" ] && [ ! -f "/etc/apache2/sites-available/200-$ServerName.conf" ]; then
        show_error "vHost $ServerName not found.  Aborting."
        exit 1
    fi

    # Remove legacy non-prefixed version first:
    if [ -f "/etc/apache2/sites-enabled/$ServerName.conf" ]; then
        cd /etc/apache2/sites-available/ && a2dissite ${ServerName}.conf
        rm /etc/apache2/sites-available/${ServerName}.conf
    fi

    # Remove new prefixed version next:
    if [ -f "/etc/apache2/sites-enabled/200-$ServerName.conf" ]; then
        cd /etc/apache2/sites-available/ && a2dissite 200-${ServerName}.conf
        rm /etc/apache2/sites-available/200-${ServerName}.conf
    fi

    service apache2 reload
}

function parse_php_version {
    local config_php i
    source /vagrant/config_php.sh
    for i in "${config_php[@]}"; do
        local arr=(${i// / })
        local phpv=${arr[0]}
        local phpn=${arr[1]}
        local phpp=${arr[2]}
        if [ ${PhpVersion} == ${phpn} ]; then
            PhpPort=${phpp}
        fi
    done;
    if [ -z ${PhpPort+x} ]; then
        show_error "Unsupported PHP version [$PhpVersion].  Supported versions are: [$(get_php_versions)].  Aborting."
        exit 1
    fi
}

function show_error {
    show_usage
    echo -e "\e[31m${1}\e[0m"
}

function vhost_list {
    local a arr config configs config_php d i n p port phpn phpp phpv out
    configs="$(ls -1 /etc/apache2/sites-enabled/200-*.conf 2>/dev/null)"
    source /vagrant/config_php.sh

    out=''
    for config in ${configs[@]} ; do
        filename=${config}
        file=$(cat $filename)
        a=$(echo "$file" | head -n20 | grep 'ServerAlias' | xargs | sed "s/ServerAlias /-a*/g")
        d=$(echo "$file" | grep 'DocumentRoot' | head -n1 | xargs | cut -d' ' -f2)
        n=$(echo "$file" | grep 'ServerName ' | head -n1 | xargs | cut -d' ' -f2)
        port=$(echo "$file" | grep '<Proxy fcgi://127.0.0.1:' | xargs | head -n1 | cut -d':' -f3 | cut -d'>' -f1)
        p=''
        for i in "${config_php[@]}"; do
            arr=(${i// / })
            phpv=${arr[0]}
            phpn=${arr[1]}
            phpp=${arr[2]}
            if [ "${port}" = "${phpp}" ]; then
                p=${phpn}
            fi
        done;

        if [ "$a" != "" ] ; then a=" $a"    ; fi
        if [ "$d" != "" ] ; then d=" -d*$d" ; fi
        if [ "$n" != "" ] ; then n=" -n*$n" ; fi   
        if [ "$p" != "" ] ; then p=" -p*$p" ; fi

        out="${out}****sudo*vhost*add*${n}${p}${d}${a} -f;
"
    done
    echo "${out}" | column -t | sed "s/*/ /g"
}

function vhost_sites {
    local arr sites vhost vhosts
    vhosts=$(vhost_list)

    if [ "${vhosts}" != "" ]; then
        echo "${vhosts}" | while read line ; do
            arr=(${line// / })
            echo "    * https://${arr[4]}";
        done
    fi
}

# Set Defaults
CertPath=""
KeyPath=""
ServerAlias=""
PhpVersion=""
force="n"
Task=''

# Transform long options to short ones
for arg in "$@"; do
  case "$arg" in
    "add")
        shift
        # set -- "$@" "-A"
        Task='add'
        ;;
    "remove")
        shift
        # set -- "$@" "-R"
        Task='remove'
        ;;
    "list")
        shift
        # set -- "$@" "-L"
        Task='list'
        ;;
    "sites")
        shift
        # set -- "$@" "-S"
        Task='sites'
        ;;
     *)
        set -- "$@" "$arg"
  esac
done

# Parse flags
ServerAlias=""
Force='n'
while getopts "d:s:k:a:p:n:c:h:ARLSf" OPTION; do
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
            if [[ $(echo "${ServerAlias}" | grep ${OPTARG}) == '' ]]; then
                ServerAlias+="ServerAlias ${OPTARG}\n    "
            fi
            ;;
        p)
            PhpVersion=$OPTARG
            ;;
        s)
            CertPath=$OPTARG
            ;;
        k)
            KeyPath=$OPTARG
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
        L)
            Task="list"
            ;;
        S)
            Task="sites"
            ;;
        f)
            Force="y"
            ;;
    esac
done


case ${Task} in
    list)
        vhost_list
        ;;
    sites)
        vhost_sites
        ;;
    add)
        if [ "$(id -u)" != "0" ] ; then
            show_header
            show_error "Command \e[1mvhost add \e[0;31mmust be run with 'sudo' or as root.  Aborting."
            exit 1
        fi
        if [ "${PhpVersion}" != "" ]; then
            parse_php_version
        fi
        if [ "$ServerName" = "" ] ; then
            show_header
            show_error "Missing Server Name.  Aborting."
            exit 1
        elif [ "$DocumentRoot" == "" ]; then
            show_header
            show_error "DocumentRoot must be set.  Aborting."
            exit 1
        elif [ "$CertPath" != "" ] && [ "$KeyPath" == "" ]; then
            show_header
            show_error "When supplying CertPath, KeyPath must also be supplied.  Aborting."
            exit 1
        elif [ "$CertPath" == "" ] && [ "$KeyPath" != "" ]; then
            show_header
            show_error "When supplying KeyPath, CertPath must also be supplied.  Aborting."
            exit 1
        elif [ -f "/etc/apache2/sites-available/$ServerName.conf" ] || [ -f "/etc/apache2/sites-available/200-$ServerName.conf" ]; then
            if confirm "vHost $ServerName already exists. Remove and Recreate it? [y/N]" ; then
                remove_vhost
            else
                exit 1
            fi
        fi
        add_vhost
        ;;
    remove)
        if [ "$(id -u)" != "0" ] ; then
            show_header
            show_error "Command \e[1mvhost remove \e[0;31mmust be run with 'sudo' or as root.  Aborting."
            exit 1
        fi
        if [ "$ServerName" = "" ] ; then
            show_header
            show_error "Missing Server Name.  Aborting."
            exit 1
        fi
        if [ ! -f "/etc/apache2/sites-available/$ServerName.conf" ] && [ ! -f "/etc/apache2/sites-available/200-$ServerName.conf" ]; then
            show_error "vHost $ServerName not present"
            exit 1
        fi
        confirm "Remove vHost $ServerName? [y/N]" && remove_vhost
        ;;
    *)
        show_header
        show_usage
        exit 1
        ;;
esac

