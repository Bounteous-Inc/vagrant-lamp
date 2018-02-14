# Useful Aliases
alias lh='ls -alh'
alias sudo='sudo '
alias mem='free | awk '\''/Mem/{printf("Memory used: %.2f%"), $3/$2*100} /buffers\/cache/{printf(", buffers: %.2f%\n"), 100-($4/($3+$4)*100)}'\'''
alias www='cd /srv/www'


# Vagrant helper functions and aliases:
function vhelp {
    local _versions=''
    local _vhost_sites="$(vhost sites | sed 's/$/\\n/g' | tr -d '\n')"
    local config_php
    source /vagrant/config_php.sh
    for i in "${config_php[@]}"; do
        arr=(${i// / })
        phpv=${arr[0]}
        phpn=${arr[1]}
        phpv_x=${phpv}'     '
        phpn_x=${phpn}'     '
        line="    * PHP ${phpv_x:0:6}      - alias php${phpn}"
        _versions="${_versions}${line}\n"
    done;

    text=$(sed "s|###php_versions###|${_versions}|g" /vagrant/files/welcome.txt | sed "s|###vhost_sites###|${_vhost_sites}|g");
    echo -e "$text"
}

function vstatus {
    echo -e "\n\033[1;32mvstatus - Vagrant Status\033[0;32m"
    echo -e "  Disk Used:      `df -h --output='pcent' / | tail -n1` (Vagrant) `df -h --output='pcent' /vagrant | tail -n1` (Host)"
    echo -e "  `free | awk '/Mem/{printf(\"Memory used:     %.0f% (RAM)\"), $3/$2*100} /buffers\/cache/{printf(\"      %.0f% (Buffers)\"), 100-($4/($3+$4)*100)}'`\n"
    echo -e "  Apache2 Status:  $(if [[ $(sudo service apache2      status | grep 'not running') == '' ]]; then echo '\033[1;32mOK\033[0;32m'; else echo '\033[1;31mStopped\033[0;32m'; fi)"
    echo -e "  Mysql Status:    $(if [[ $(sudo service mysql        status | grep 'is stopped')  == '' ]]; then echo '\033[1;32mOK\033[0;32m'; else echo '\033[1;31mStopped\033[0;32m'; fi)"
    echo -e "  Redis Status:    $(if [[ $(sudo service redis-server status | grep 'not running') == '' ]]; then echo '\033[1;32mOK\033[0;32m'; else echo '\033[1;31mStopped\033[0;32m'; fi)"
    echo -e "\033[0m"
}

