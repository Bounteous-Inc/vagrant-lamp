# Change Log

## [1.0.13](https://github.com/demacmedia/vagrant-lamp/tree/1.0.13) (2018-03-09)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.12...1.0.13)

    - Fixed error when `plugin.index("(")` returns `nil`
    - Removed unnecessary pre-definition of users and groups other than mysql

## [1.0.12](https://github.com/demacmedia/vagrant-lamp/tree/1.0.12) (2018-02-17)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.11...1.0.12)

    - Added monitoring of varnish service to vstatus
    - Modified README.md to remove internal changelog section
    - Added CHANGELOG.md - partially automated with github_changelog_generator
        - Install that product with `sudo gem install github_changelog_generator`
        - Run like this: github_changelog_generator -u demacmedia -p vagrant-lamp -t [add your github API here]
        - A Github Personal Access token can be generated via Settings / Developer settings / Personal Access Tokens
           The token should allow the follwoing operations: `public_repo, repo:status, repo_deployment`

## [1.0.11](https://github.com/demacmedia/vagrant-lamp/tree/1.0.11) (2018-02-15)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.10...1.0.11)

    - Refactor/Updates
        - 000-setup_environment.sh updated grep command to use a count comparison when checking if aliases exist in .bash_aliases
        - 000-setup_environment.sh replaced 'freetype*' with specific 'libfreetype6-dev' in php pre-requisites
        - 400-setup_mysql.sh added if condition to avoid overwrite existing mysql data with that of a fresh install
        - 500-setup_php.sh moved sed replace commands into seperate condition to handle old php-farm pulls

## [1.0.10](https://github.com/demacmedia/vagrant-lamp/tree/1.0.10) (2018-02-15)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.9...1.0.10)

    - Bug fix for correct sourcing of multiple alias files following refactoring

## [1.0.9](https://github.com/demacmedia/vagrant-lamp/tree/1.0.9) (2018-02-14)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.8...1.0.9)

    - Cleanup following modularisation of aliases

## [1.0.8](https://github.com/demacmedia/vagrant-lamp/tree/1.0.8) (2018-02-14)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.7...1.0.8)

    - Modularised aliases into separate files for easier customisation of packages

## [1.0.7](https://github.com/demacmedia/vagrant-lamp/tree/1.0.7) (2018-02-13)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.6...1.0.7)

    - Tidied up aliases and functions and formatted for four spaces indenting

## [1.0.6](https://github.com/demacmedia/vagrant-lamp/tree/1.0.6) (2018-02-10)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.5...1.0.6)

    - vhost now supports new modes - list and sites - and php is optional
    - Welcome message now shows sites that are installed

## [1.0.5](https://github.com/demacmedia/vagrant-lamp/tree/1.0.5) (2018-02-06)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.4...1.0.5)

    - Tweak to /etc/mysql/my.cnf to support longer blobs in imported data dumps
    - Added MIT Licence

## [1.0.4](https://github.com/demacmedia/vagrant-lamp/tree/1.0.4) (2018-01-23)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.3...1.0.4)

    - Changes to `vhost` command to allow it to support multiple aliases in a single operation
    - Changes to `vhost` command to add -f (force) flag that can bypass confirmation messages
    - Provisioner script now identifies and upgrades all existing legacy vhost configurations to support SSL and be backed up by the `backupWebconfig` command

## [1.0.3](https://github.com/demacmedia/vagrant-lamp/tree/1.0.3) (2018-01-18)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.2...1.0.3)

    - Added n98-magerun2 and simple alias `n98` that automatically selects correct version of n98 for the instance in question

## [1.0.2](https://github.com/demacmedia/vagrant-lamp/tree/1.0.2) (2018-01-16)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.1...1.0.2)

    - Major refactoring to allow php versions, users and groups to be configured much more easily
    - PHP 7.0.8 replaces PHP 7.0.6 and freeType support added for all PHP versions
    - Added two new mandatory external shares /srv/backup and /srv/mysql used for backups and live mysql databases
    - Mysql databases now live on host machine and so can survive a `vagrant destroy` / `vagrant up` cycle
    - Added `vhelp` command with user help
    - Added `vstatus` command to show memory and disk use and availablity of key services
    - Added `xdebug` command for simple enabling / disabling of XDebug in all installed PHP instances added
    - Added `backypMysql` / `restoreMysql` for easy backup / restore of all mysql databases and users to the external /srv/backup mount
    - Added `backupWebconfig` / `restoreWebconfig` for easy backup / restore of all newly added vhosts and associated SSL certificates
    - Added `phpRestart` to restart all installed php FPM services in a single operation

## [1.0.1](https://github.com/demacmedia/vagrant-lamp/tree/1.0.1) (2017-10-17)
[Full Changelog](https://github.com/demacmedia/vagrant-lamp/compare/1.0.0...1.0.1)

    - Added SSL support for `vhost` function (was on a separate branch)

## [1.0.0](https://github.com/demacmedia/vagrant-lamp/tree/1.0.0) (2016-04-01 to 2017-02-03)
    - Initial unversioned releases
