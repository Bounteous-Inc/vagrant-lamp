# Demac Flavoured vagrant-lamp

### Goal
The goal of this project is to create an easy to use, reliable development environment.
Built off the same ideas as the LAMP stack for Magento, this has been designed with Weblinc/Workarea in mind 

### Requirements

- [Vagrant 1.8+](https://www.vagrantup.com/downloads.html)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Setup

    # Install git and DemacMedia/Vagrant-Lamp
    git clone -b RubyStack https://github.com/DemacMedia/vagrant-lamp.git vagrant-lamp-ruby
    cd vagrant-lamp-ruby

    # Copy example.config.yml to config.yml and edit options
    cp example.config.yml config.yml
    vim config.yml

    # Run Vagrant Up to download and setup the VM
    vagrant up

###Configuration
####NOTE: Default vagrant IP is 192.168.33.11 to not conflict with the PHP Stack. This allows both versions to be installed and used.
-   Guest Host Entries:
    -   Add host entries to files/hosts.txt to have them added to Guest machine on provisioning
-   config.yml settings
    -   vagrant_hostname: Hostname on Guest VM `OPTIONAL - can leave default demacrvm.dev`
    -   vagrant_machine_name: Vagrant Machine Name, used for creating unique VM `OPTIONAL - can leave default demacrvm`
    -   vagrant_ip: IP addressed used to access Guest VM from Local machine `OPTIONAL - can leave default 192.168.33.11`
    -   vagrant_public_ip: Public IP address of VM `OPTIONAL - recommended leave defualt empty`
    -   vagrant_synced_folders: Shared Folders from HOST machine to Guest
        -   local_path: Path on Host machine to share
        -   destination: Path on Guest machine to mount share
        -   type: Share Type \[[nfs](https://www.vagrantup.com/docs/synced-folders/nfs.html)|[smb](https://www.vagrantup.com/docs/synced-folders/smb.html)|[rsync](https://www.vagrantup.com/docs/synced-folders/rsync.html)\] `OPTIONAL - recommended  'nfs' for OSX and leave defualt/empty for Windows`
        -   create: Create directory on HOST machine if it doesn't exist `OPTIONAL - recommended leave defualt true`
        ```
        #Example of Multiple Shared Folders
        vagrant_synced_folders:
          - local_path: ~/Sites/projects_directory
            destination: /srv/www
            type:
            create: true
          - local_path: ~/Sites/projects_directory2
            destination: /srv/www2
            type:
            create: true
        ```
    -   vagrant_memory: Memory to assign to VM `OPTIONAL - can leave default 2048, recommended 3096`
    -   vagrant_cpus: CPU Cores to assign to VM `OPTIONAL - can leave default 2`
    -   weblinc_username: Weblinc gem repo username
    -   weblinc_password: Weblinc gem repo password

####The following are installed:

-   Apache2 with mpm\_event
-   Passenger for Apache Ruby/Rails integration
-   Varnish
-   Redis
-   Rbenv
-   Ruby 2.3.1
-   Open JDK 7
-   ElasticSearch
-   PhatomJs
-   Mongo DB
-   Imagemagick
-   HTOP
-   dos2unix
-   smem
-   strace
-   lynx


####The following Extra Tools are available:
-   redis-setup (Added to PATH)
    - Add,Remove or List Redis instances

        ```Usage: redis-setup add|remove|list -n name [-p port] [-s save]```
-   vhost (Added to PATH) *Ruby version
    - Add,Remove Apache virtualhost entries

        ```Usage: vhost add|remove -d DocumentRoot -n ServerName [-a ServerAlias] [-s CertPath] [-c CertName]```
