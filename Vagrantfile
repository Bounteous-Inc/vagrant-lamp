# -*- mode: ruby -*-
# vi: set ft=ruby :
mounts_required = Array.[]('/srv/www', '/srv/mysql', '/srv/backup')

# Use config.yml for basic VM configuration.
require 'yaml'
require File.dirname(__FILE__)+"/files/dependency_manager"
dir = File.dirname(File.expand_path(__FILE__))
unless File.exist?("#{dir}/config.yml")
  raise 'Configuration file not found! Please copy example.config.yml to config.yml and try again.'
end
vconfig = YAML.load_file("#{dir}/config.yml")

mounts_required.each do |required_folder|
  found = false
  vconfig['vagrant_synced_folders'].each do |synced_folder|
    if synced_folder['destination'] == required_folder
      found = true
    end
  end
  if found == false
    puts "\n" +
      '**********************' + "\n" +
      '* Demac Vagrant Lamp *' + "\n" +
      '**********************' + "\n" +
      'Your config.yml file must contain ' +
      mounts_required.count.to_s +
      ' vagrant_synced_folders entries' + "\n" +
      'mapping to ' + mounts_required.to_s + "\n" +
      "Please see example.config.yml for details on how to set this.\n" +
      "\n"
    exit
  end
end

module OS
    def OS.windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def OS.mac?
        (/darwin/ =~ RUBY_PLATFORM) != nil
    end

    def OS.unix?
        !OS.windows?
    end

    def OS.linux?
        OS.unix? and not OS.mac?
    end
end

if OS.mac?
   check_plugins ["vagrant-bindfs"]
end

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/xenial64"

  # Networking configuration.
  config.vm.hostname = vconfig['vagrant_hostname']
  if vconfig['vagrant_ip'] == '0.0.0.0' && Vagrant.has_plugin?('vagrant-auto_network')
    config.vm.network :private_network, ip: vconfig['vagrant_ip'], auto_network: true
  else
    config.vm.network :private_network, ip: vconfig['vagrant_ip']
  end

  if !vconfig['vagrant_public_ip'].empty? && vconfig['vagrant_public_ip'] == '0.0.0.0'
    config.vm.network :public_network
  elsif !vconfig['vagrant_public_ip'].empty?
    config.vm.network :public_network, ip: vconfig['vagrant_public_ip']
  end

  # Synced folders.
  vconfig['vagrant_synced_folders'].each do |synced_folder|
    options = {
      type: synced_folder['type'],
      rsync__auto: 'true',
      rsync__exclude: synced_folder['excluded_paths'],
      rsync__args: ['--verbose', '--archive', '--delete', '-z', '--chmod=ugo=rwX'],
      id: synced_folder['id'],
      create: synced_folder.include?('create') ? synced_folder['create'] : false,
      mount_options: synced_folder.include?('mount_options') ? synced_folder['mount_options'] : []
    }

    owner = 'vagrant'
    group = 'vagrant'

    if synced_folder['type'] != 'nfs' || Vagrant::Util::Platform.windows?
       options[:owner] = owner
       options[:group] = group
       options[:mount_options] = ["dmode=775,fmode=664"]
    end

    if synced_folder.include?('options_override')
      options = options.merge(synced_folder['options_override'])
    end

    if synced_folder['type'] == 'nfs' && !Vagrant::Util::Platform.windows?
      config.vm.synced_folder synced_folder['local_path'], '/nfs' + synced_folder['destination'], options
      config.bindfs.bind_folder "/nfs" + synced_folder['destination'], synced_folder['destination'], :owner => owner, :group => group, :'create-as-user' => true, :perms => "u=rwx:g=rwx:o=r", :'create-with-perms' => "u=rwx:g=rwx:o=r", :'chown-ignore' => true, :'chgrp-ignore' => true, :'chmod-ignore' => true
    else
      config.vm.synced_folder synced_folder['local_path'], synced_folder['destination'], options
    end
  end

  # VirtualBox.
  config.vm.provider :virtualbox do |vb|
    vb.linked_clone = true if Vagrant::VERSION =~ /^1.8/
    vb.name = vconfig['vagrant_hostname']
    vb.memory = vconfig['vagrant_memory']
    vb.cpus = vconfig['vagrant_cpus']
    vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    vb.customize ['modifyvm', :id, '--ioapic', 'on']
  end

  # Run all setup scripts in numbered order:
  @files = Dir.glob("#{dir}/scripts/*.sh").sort.each do |setup_script|
    provision_name = setup_script.split('/')[-1].split('-')[1].split('.')[0]
    # puts "#{provision_name} #{setup_script}"
    config.vm.provision provision_name, type: "shell", path: setup_script
  end

  config.vm.define vconfig['vagrant_machine_name']

  # Make mysql's socket available to php - e.g.
  # echo "<?php \$li = new mysqli('localhost', 'root', 'root', 'mysql'); ?>" | php
  config.vm.provision "shell", inline: "if [ ! -L /tmp/mysql.sock ]; then ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock; fi", run: "always"

  config.vm.provision "shell", inline: "service mysql restart", run: "always"

end
