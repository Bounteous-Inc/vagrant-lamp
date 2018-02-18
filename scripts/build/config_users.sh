#!/usr/bin/env bash

if [ ! -f /vagrant/config_users.sh ]; then
    cat > /vagrant/config_users.sh << EOF
#!/usr/bin/env bash
####Auto Generate File DO NOT MODIFY###
config_users=(
)
####Auto Generate File DO NOT MODIFY###
EOF
fi

sed -i "s|)|   '$1 $2 $3 $4 $5 \"$6\"'\\n)|" /vagrant/config_users.sh