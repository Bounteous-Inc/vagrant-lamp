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

apt-get update

# Install git, tig, htop, smem, strace, lynx and dos2unix
apt-get install -y git tig htop smem strace lynx dos2unix 2>&1

# Correct non Unix line endings
find /vagrant/files -type f -exec dos2unix {} \;
dos2unix /vagrant/config_php.sh
dos2unix /vagrant/config_groups.sh
dos2unix /vagrant/config_groups.sh


# Setup Hosts file
while IFS='' read -r line || [[ -n "$line" ]]; do
  if ! grep -q "$line" /etc/hosts ; then
    echo "$line" >> /etc/hosts
  fi
done </vagrant/files/hosts.txt


# Copy bash aliases and welcome message for all users
cp /vagrant/files/00-aliases.sh /etc/profile.d/
cp /vagrant/files/99-welcome.sh /etc/profile.d/

# Next line needed so that root will have access to these aliases
if [ ! grep -q "source /etc/profile.d/00-aliases.sh" /root/.bash_aliases ] ; then
  echo "source /etc/profile.d/00-aliases.sh" >> /root/.bash_aliases
fi

#Setup PHP compile pre-requisites
apt-get install -y  build-essential libbz2-dev libmysqlclient-dev libxpm-dev libmcrypt-dev \
    libcurl4-gnutls-dev libxml2-dev libjpeg-dev libpng12-dev libssl-dev pkg-config libreadline-dev \
    curl autoconf libicu-dev libxslt-dev freetype* 2>&1

# Workaround to allow custom scripts added to path with sudo
if ! grep -q "^#Defaults[[:blank:]]*secure_path" /etc/sudoers ; then
    sed -i 's/^Defaults[[:blank:]]*secure_path/#Defaults       secure_path/' /etc/sudoers
fi
