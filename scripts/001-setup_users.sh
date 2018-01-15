#!/usr/bin/env bash
echo "******************************"
echo "* 001-setup_users.sh         *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

function vagrant_groups() {
    local arr
    local config_groups
    local group_newGID
    local group_name
    local group_name_padded
    local group_oldGID
    local i

    source /vagrant/config_groups.sh

    # Create groups if they don't exist already.
    # Change gid for any groups that are not assigned as expected, and remap any associated files and folders
    for i in "${config_groups[@]}"; do
        arr=(${i// / })
        group_newGID=${arr[0]}
        group_name=${arr[1]}
        group_name_padded={${arr[1]}'         '}

        if [ ! $(getent group ${group_name}) ]; then
           echo "Creating new group ${group_name_padded:1:12} with gid ${group_newGID}"
           groupadd -g ${group_newGID} ${group_name}
        fi

        if [ $(getent group ${group_name} | cut -d':' -f3) != ${group_newGID} ]; then
           group_oldGID=$(getent group ${group_name} | cut -d':' -f3)
           echo "Remapping existing group ${group_name_padded:1:12} from GID ${group_oldGID} to GID ${group_newGID}"
           groupmod -g ${group_newGID} ${group_name}
           echo "Reassigning files and folders associated with old group id to the new one"
           $(find / -gid ${group_oldGID} '!' -type l -exec chgrp ${group_newGID} '{}' ';' 2>&1 | grep -v 'No such file or directory') || true
        fi
    done
}

function vagrant_users() {
    local arr
    local config_users
    local i
    local user_newUID
    local user_newGID
    local user_name
    local user_name_padded
    local user_homeDir
    local user_shell
    local user_comment
    local user_oldUID
    local user_oldGID
    local user_homeDir_arg
    local user_shell_arg
    local user_comment_arg

    source /vagrant/config_users.sh

    # Create users if they don't exist already.
    # Change uid and gid for any users that are not assigned as expected, and remap any associated files and folders
    for i in "${config_users[@]}"; do
        arr=(${i// / })
        user_newUID=${arr[0]}
        user_newGID=${arr[1]}
        user_name=${arr[2]}
        user_name_padded={${arr[2]}'         '}
        user_homeDir=${arr[3]}
        user_shell=${arg[4]}
        user_comment=${arg[5]}

        if [ ${user_homeDir} == '-' ]; then user_homeDir_arg='-M' ; else user_homeDir_arg="-d ${user_homeDir}"         ; fi
        if [ ${user_shell} == '-' ];   then user_shell_arg=' '    ; else   user_shell_arg="-s ${user_shell}"           ; fi
        if [ ${user_comment} == '-' ]; then user_comment_arg=' '  ; else user_comment_arg="-c '${user_comment//-/ /}'" ; fi

        if [ ! $(id -u ${user_name}) ]; then
           echo "Creating new user ${user_name_padded:1:12} with uid ${user_newUID} and gid ${user_newGID}"           
           useradd -u ${user_newUID} -g ${user_newGID} ${user_homeDir_arg} ${user_comment_arg} ${user_shell_arg} ${user_name}
        fi

        if [ $(id -u ${user_name}) != ${user_newUID} ]; then
           user_oldUID=$(id -u ${user_name})
           echo "Remapping existing user ${user_name_padded:1:12} from UID ${user_oldUID} to UID ${user_newUID}"
           usermod -u ${user_newUID} ${user_name}
           echo "Reassigning files and folders associated with old user id to the new one"
           $(find / -uid ${user_oldUID} '!' -type l -exec chown ${user_newUID} '{}' ';' 2>&1 | grep -v 'No such file or directory') || true
        fi

        if [ $(id -g ${user_name}) != ${user_newGID} ]; then
           user_oldGID=$(id -g ${user_name})
           echo "Remapping existing user ${user_name_padded:1:12} from GID ${user_oldGID} to UID ${user_newGID}"
           usermod -g ${user_newGID} ${user_name}
        fi

    done
}

function vagrant_services {
    local arr
    local i
    local services

    services=('apache2 mysql redis-server varnish')
    arr=(${services// / })
    for i in "${arr[@]}"; do
        sudo service ${i} ${1} || true
    done
}

vagrant_services stop
vagrant_groups
vagrant_users
vagrant_services start

