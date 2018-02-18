#!/usr/bin/env bash

if [ ! -f /vagrant/config_php.sh ]; then
    cat > /vagrant/config_php.sh << EOF
#!/usr/bin/env bash
####Auto Generate File DO NOT MODIFY###
config_php=(
)
####Auto Generate File DO NOT MODIFY###
EOF
fi

sed -i "s/)/\   '$1 $2 $3 $4'\\n)/" /vagrant/config_php.sh