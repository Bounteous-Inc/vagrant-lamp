#!/usr/bin/env bash

if [ ! -f /etc/apt/sources.list.d/passenger.list ]; then
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
    sudo apt-get install -y apt-transport-https ca-certificates

    sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list'
    sudo apt-get update
    sudo apt-get install -y libapache2-mod-passenger
    sudo a2enmod passenger
    sudo apache2ctl restart
    sudo /usr/bin/passenger-config validate-install
fi

if [ ! -x "$(command -v rbenv)" ]; then
    cd /home/vagrant
    git clone git://github.com/sstephenson/rbenv.git .rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(rbenv init -)"' >> ~/.bash_profile

    git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bash_profile
    source ~/.bash_profile
    rbenv install -v 2.3.1
    rbenv global 2.3.1
fi

if [ -n "$1" ] && [ -n "$2" ]; then
    gem sources --add https://$1:$2@gems.weblinc.com
fi

gem update --system

if [ ! -x "$(command -v rails)" ]; then
    gem update --system
    gem install rails -v 4.2.7.1
fi

if ! `gem list bundle -i`; then
    gem install bundler
fi

if [ -n "$1" ] && [ -n "$2" ]; then
    bundle config gems.weblinc.com $1:$2
fi

if ! `gem list execjs -i`; then
    gem install execjs
    sudo apt-get install -y nodejs
fi

