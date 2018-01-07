#!/usr/bin/env bash
echo "******************************"
echo "* 000-setup_environment.sh   *"
echo "******************************"

if [ ! -d /srv/backup ] || [ ! -d /srv/mysql ] || [ ! -d /srv/www ]; then
    echo -e "\033[1;31mError:\033[0;31m Your config.yml file must include shared mounted folders mapping to /srv/backup, /srv/mysql and /srv/www\033[0m"
    echo -e "\033[0;31mPlease see example.config.yml for how to do set this up.\033[0m"
    echo -e "\033[0;31mThe current operation has been aborted.\033[0m"
    exit 1
fi

# Enable trace printing and exit on the first error
set -ex

# Create backup folders for mysql and web config
mkdir -p /srv/backup/mysql
mkdir -p /srv/backup/webconfig

# Create folder for mysql data
mkdir -p /srv/mysql/data



apt-get update

# Install git
apt-get install -y git 2>&1

# Install HTOP
apt-get install -y htop 2>&1

# Install smem
apt-get install -y smem 2>&1

# Install strace
apt-get install -y strace 2>&1

# Install lynx
apt-get install -y lynx 2>&1

# Install dos2unix
apt-get install -y dos2unix 2>&1

# Correct non Unix line endings
find /vagrant/files -type f -exec dos2unix {} \;

# Setup Hosts file
while IFS='' read -r line || [[ -n "$line" ]]; do
  if ! grep -q "$line" /etc/hosts ; then
    echo "$line" >> /etc/hosts
  fi
done </vagrant/files/hosts.txt

# Create backup folders for mysql and web config
mkdir -p /srv/backup/mysql
mkdir -p /srv/backup/webconfig

# Create folder for mysql data
mkdir -p /srv/mysql/data

# Copy bash aliases and welcome message for all users
cp /vagrant/files/00-aliases.sh /etc/profile.d/
cp /vagrant/files/99-welcome.sh /etc/profile.d/

# Next line needed so that root will have access to these aliases
echo "source /etc/profile.d/00-aliases.sh" >> /root/.bash_aliases

#Setup PHP compile pre-requisites
apt-get install -y  build-essential libbz2-dev libmysqlclient-dev libxpm-dev libmcrypt-dev \
    libcurl4-gnutls-dev libxml2-dev libjpeg-dev libpng12-dev libssl-dev pkg-config libreadline-dev \
    curl autoconf libicu-dev libxslt-dev freetype* 2>&1

# Workaround to allow custom scripts added to path with sudo
if ! grep -q "^#Defaults[[:blank:]]*secure_path" /etc/sudoers ; then
    sed -i 's/^Defaults[[:blank:]]*secure_path/#Defaults       secure_path/' /etc/sudoers
fi
