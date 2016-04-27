# Demac Flavoured vagrant-lamp

### Goal
The goal of this project is to create an easy to use, reliable development environment.
This was built as a MAMP/WAMP replacement, meeting the requirements of Magento 1 & 2
specifically.

### Requirements

- [Vagrant 1.8+](https://www.vagrantup.com/downloads.html)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Setup

    # Install git and DemacMedia/Vagrant-Lamp
    git clone https://github.com/DemacMedia/vagrant-lamp.git
    cd vagrant-lamp

    # Copy example.config.yml to config.yml and edit options
    cp example.config.yml config.yml
    vim config.yml

    # Run Vagrant Up to download and setup the VM
    vagrant up

###Configuration
-   Guest Host Entries:
    -   Add host entries to files/hosts.txt to have them added to Guest machine on provisioning
-   config.yml settings
    -   vagrant_hostname: Hostname on Guest VM `OPTIONAL - can leave default demacvm.dev`
    -   vagrant_machine_name: Vagrant Machine Name, used for creating unique VM `OPTIONAL - can leave default demacvm`
    -   vagrant_ip: IP addressed used to access Guest VM from Local machine `OPTIONAL - can leave default 192.168.33.10`
    -   vagrant_public_ip: Public IP address of VM `OPTIONAL - recommended leave defualt empty`
    -   vagrant_synced_folders: Shared Folders from HOST machine to Guest
        -   local_path: Path on Host machine to share
        -   destination: Path on Guest machine to mount share
        -   type: Share Type \[[nfs](https://www.vagrantup.com/docs/synced-folders/nfs.html)|[smb](https://www.vagrantup.com/docs/synced-folders/smb.html)|[rsync](https://www.vagrantup.com/docs/synced-folders/rsync.html)\] `OPTIONAL - recommended leave defualt empty`
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

####The following are installed:

-   Apache2 with mpm\_event
-   Percona 5.6 (Server and Client)
-   Varnish
-   Redis
-   PHP-FPM 5.4, 5.5, 5.6 & 7.0 /w Xdebug (via PHPFARM)
-   HTOP
-   dos2unix
-   smem
-   strace
-   lynx


####The following Extra Tools are available:
-   Composer (Added to PATH)
-   N98-Magerun (Added to PATH)
-   modman (Added to PATH)
-   redis-setup (Added to PATH)
    - Add,Remove or List Redis instances

        ```Usage: redis-setup add|remove|list -n name [-p port] [-s save]```
-   vhost (Added to PATH)
    - Add,Remove Apache virtualhost entries

        ```Usage: vhost add|remove -d DocumentRoot -n ServerName -p PhpVersion [-a ServerAlias] [-s CertPath] [-c CertName]```
-   mysql-sync (Added to PATH)
    - Sync Remote Database to VM Mysql instance

        ```Usage: mysql-sync -i remote-ip -p remote-port -u remote-username -d remote-database```