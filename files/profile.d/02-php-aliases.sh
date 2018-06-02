# PHP functions:
function phpRestart() {
    local arr config_php i phpn
    source /vagrant/config_php.sh
    for i in "${config_php[@]}"; do
        arr=(${i// / })
        phpn=${arr[1]}
        sudo service php-${phpn} restart
    done;
}

function xdebug {
    local ini ini_files services state
    state=$([ ${1:-1} == 0 ] && echo ";");
    echo $([ ${1:-1} == 0 ] && echo "Disabling" || echo "Enabling")" X-Debug:"
    services=$(ls -a /etc/init.d/ | grep php);
    ini_files=$(ls -df /opt/phpfarm/inst/php-*/lib/php.ini);
    for ini in ${ini_files}
        do sudo sed -i "s/[;]*zend_extension=xdebug.so/${state}zend_extension=xdebug.so/g" ${ini};
    done;
    for svc in ${services}
        do echo -n "  * Restarting ${svc}... " && sudo service ${svc} restart > null && echo "done."
    done;
}

function phpErrors() {
    local ini ini_files services state
    state=$([[ ${1:-1} == 0 ]] && echo "Off" || echo "On");
    echo $([ ${1:-1} == 0 ] && echo "Disabling" || echo "Enabling")" PHP Error Display:"
    services=$(ls -a /etc/init.d/ | grep php);
    ini_files=$(ls -df /opt/phpfarm/inst/php-*/lib/php.ini);
    for ini in ${ini_files}; do
        sudo sed -i "s/display_startup_errors = .*/display_startup_errors = ${state}/g" ${ini}
        sudo sed -i "s/display_errors = .*/display_errors = ${state}/g" ${ini}
    done;
    for svc in ${services}; do
        echo -n "  * Restarting ${svc}... " && sudo service ${svc} restart > null && echo "done."
    done;
}

function makePhpShortformAliases {
    local arr config_php i phpa
    source /vagrant/config_php.sh
    for i in "${config_php[@]}"; do
        arr=(${i// / })
        phpa="php${arr[1]}='/opt/phpfarm/inst/php-${arr[0]}/bin/php'"
        alias $phpa;
    done;
}

makePhpShortformAliases

