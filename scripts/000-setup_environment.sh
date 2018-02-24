#!/usr/bin/env bash
echo "******************************"
echo "* 000-setup_environment.sh   *"
echo "******************************"

# Enable trace printing and exit on the first error
set -ex

# Create backup folders for mysql and web config
mkdir -p /srv/backup/mysql
mkdir -p /srv/backup/webconfig

# Create folder for mysql data
mkdir -p /srv/mysql/data

# Create folder for php builds
mkdir -p /vagrant/files/php_builds

# Check Box Version
if [ "$(lsb_release -sr)" != "16.04" ] ; then
    set +x
    text=$(sed "s|###version###|$(lsb_release -sr)|g" /vagrant/files/upgrade.txt);
    echo -e "$text"
    exit 1
fi

apt-get update

# Install git, tig, htop, smem, strace, lynx and dos2unix
apt-get install -y git tig htop smem strace lynx dos2unix 2>&1

# Correct non Unix line endings
find /vagrant/files -type f -exec dos2unix {} \;
dos2unix /vagrant/config_php.sh

# Setup Hosts file
while IFS='' read -r line || [[ -n "$line" ]]; do
  if ! grep -q "$line" /etc/hosts ; then
    echo "$line" >> /etc/hosts
  fi
done </vagrant/files/hosts.txt


# Removes old non-modular alias if present
rm -f /etc/profile.d/00-aliases.sh

# Copy bash aliases for all users
cp /vagrant/files/profile.d/* /etc/profile.d/

# Next line needed so that root will have access to these aliases
if [ ! -f /root/.bash_aliases ] || [ $(grep -c "for f in /etc/profile.d/\*aliases.sh; do source \$f; done" /root/.bash_aliases) -eq 0 ] ; then
    echo 'for f in /etc/profile.d/*-aliases.sh; do source $f; done' >> /root/.bash_aliases
fi

#Setup PHP compile pre-requisites
apt-get install -y  build-essential libbz2-dev libmysqlclient-dev libxpm-dev libmcrypt-dev \
    libcurl4-gnutls-dev libxml2-dev libjpeg-dev libpng12-dev libssl-dev pkg-config libreadline-dev \
    curl autoconf libicu-dev libxslt-dev libfreetype6-dev 2>&1

# Workaround to allow custom scripts added to path with sudo
if ! grep -q "^#Defaults[[:blank:]]*secure_path" /etc/sudoers ; then
    sed -i 's/^Defaults[[:blank:]]*secure_path/#Defaults       secure_path/' /etc/sudoers
fi
