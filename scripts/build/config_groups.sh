#!/usr/bin/env bash

if [ ! -f /vagrant/config_groups.sh ]; then
    cat > /vagrant/config_groups.sh << EOF
#!/usr/bin/env bash
####Auto Generate File DO NOT MODIFY###
config_groups=(
)
####Auto Generate File DO NOT MODIFY###
EOF
fi

sed -i "s/)/\   '$1 $2'\\n)/" /vagrant/config_groups.sh