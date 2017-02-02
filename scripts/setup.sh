#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

apt-get update

# Install git
apt-get install -y git

# Install HTOP
apt-get install -y htop

# Install smem
apt-get install -y smem

# Install strace
apt-get install -y strace

# Install lynx
apt-get install -y lynx

# Install dos2unix
apt-get install -y dos2unix

# Correct non Unix lind endings
find /vagrant/files -type f -exec dos2unix {} \;

# Setup Hosts file
while IFS='' read -r line || [[ -n "$line" ]]; do
  if ! grep -q "$line" /etc/hosts ; then
    echo "$line" >> /etc/hosts
  fi
done </vagrant/files/hosts.txt

#Setup PHP compile pre-requisites
apt-get install -y  build-essential libbz2-dev libmysqlclient-dev libxpm-dev libmcrypt-dev \
    libcurl4-gnutls-dev libxml2-dev libjpeg-dev libpng12-dev libssl-dev pkg-config libreadline-dev \
    curl autoconf libicu-dev libxslt-dev

# Workaround to allow custom scripts added to path with sudo
if ! grep -q "^#Defaults[[:blank:]]*secure_path" /etc/sudoers ; then
    sed -i 's/^Defaults[[:blank:]]*secure_path/#Defaults       secure_path/' /etc/sudoers
fi

# Add dialout group to vagrant user for NFS mounts
usermod -a -G dialout vagrant