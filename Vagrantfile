# -*- mode: ruby -*-
# vi: set ft=ruby :

# Use config.yml for basic VM configuration.
require 'yaml'
require File.dirname(__FILE__)+"/files/dependency_manager"
dir = File.dirname(File.expand_path(__FILE__))
unless File.exist?("#{dir}/config.yml")
  raise 'Configuration file not found! Please copy example.config.yml to config.yml and try again.'
end
vconfig = YAML.load_file("#{dir}/config.yml")
if !Vagrant::Util::Platform.windows?
   check_plugins ["vagrant-bindfs"]
end

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/trusty64"

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

  config.vm.network "forwarded_port", guest: 27017, host: 27017

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
    if synced_folder.include?('options_override')
      options = options.merge(synced_folder['options_override'])
    end	
    if synced_folder['type'] == 'nfs' && !Vagrant::Util::Platform.windows?
	  config.vm.synced_folder synced_folder['local_path'], '/nfs' + synced_folder['destination'], options
	  config.bindfs.bind_folder "/nfs" + synced_folder['destination'], synced_folder['destination'], :owner => "vagrant", :group => "vagrant", :'create-as-user' => true, :perms => "u=rwx:g=rwx:o=r", :'create-with-perms' => "u=rwx:g=rwx:o=r", :'chown-ignore' => true, :'chgrp-ignore' => true, :'chmod-ignore' => true
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

  config.vm.provision "setup_environment", type: "shell", path: "scripts/setup.sh"
  config.vm.provision "setup_apache", type: "shell", path: "scripts/setup-apache.sh"
  config.vm.provision "setup_varnish", type: "shell", path: "scripts/setup-varnish.sh"
  config.vm.provision "setup_redis", type: "shell", path: "scripts/setup-redis.sh"
  config.vm.provision "setup_ruby", type: "shell",  privileged: false, path: "scripts/setup-ruby.sh", args: vconfig['weblinc_username'] + " " + vconfig['weblinc_password']
  config.vm.provision "setup_phantomjs", type: "shell", path: "scripts/setup-phantomjs.sh"
  config.vm.provision "setup_imagemagick", type: "shell", path: "scripts/setup-imagemagick.sh"
  config.vm.provision "setup_mongodb", type: "shell", path: "scripts/setup-mongodb.sh"
  config.vm.provision "setup_java", type: "shell", path: "scripts/setup-java.sh"
  config.vm.provision "setup_elasticsearch", type: "shell", path: "scripts/setup-elasticsearch.sh"
  config.vm.provision "setup_tools", type: "shell", path: "scripts/setup-tools.sh"
  config.vm.provision "setup_finish", type: "shell", path: "scripts/setup-finish.sh"

  config.vm.define vconfig['vagrant_machine_name']

end
