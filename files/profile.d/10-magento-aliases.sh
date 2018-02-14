# Magento functions:
function m1m2 {
    if [ -e app/etc/local.xml ]; then
        echo 'M1';
    elif [ -e app/etc/env.php ]; then
        echo 'M2';
    else
        echo -e '\e[1;31mERROR:\e[0;31m Cannot determine magento version in use at '`pwd`'\e[0m';
    fi;
}

function cac {
    case $(m1m2) in
        M1)
            echo 'Cache clear for M1';
            rm -rf var/cache;
            rm -rf var/full_page_cache;
            rm -f var/classpathcache.php;
            ;;
        M2)
            echo 'Cache clear for M2';
            eval php7 bin/magento cache:flush;
            ;;
        *)
            echo $(m1m2);
            ;;
    esac
}

function connectDb {
    case $(m1m2) in
        M1 | M2)
            export MYSQL_PWD=$(getMSetting 'password');
            mysql -h$(getMSetting host) -u$(getMSetting 'username') $(getMSetting 'dbname');
            export MYSQL_PWD='';
            ;;
        *)
            echo $(m1m2)
            ;;
    esac
}

function err {
    clear;
    cat "var/report/${1:-$(ls -t var/report/* | head -1 | cut -d'/' -f3)}"
    echo ""
}

function getMSetting {
    case $(m1m2) in
        M1)
            grep "<${1}>" app/etc/local.xml | cut -d'[' -f3 | cut -d']' -f1;
            ;;
        M2)
            echo "<?php \$test=include('./app/etc/env.php'); print_r(\$test['db']['connection']['default']['${1}']) ?>" | php;
            ;;
        *)
            echo $(m1m2)
            ;;
    esac
}

function m1m2 {
    if [ -e app/etc/local.xml ]; then
        echo 'M1';
    elif [ -e app/etc/env.php ]; then
        echo 'M2';
    else
        echo -e '\e[1;31mERROR:\e[0;31m Cannot determine magento version in use at '`pwd`'\e[0m';
    fi;
}

function templateHelp  {
    case $(m1m2) in
        M1)
            echo "UPDATE core_config_data SET value=${1:-1} where path IN('dev/debug/template_hints', 'dev/debug/template_hints_blocks');" | connectDb;
            cac;
            ;;
        M2)
            php bin/magento dev:template-hints:enable;
            ;;
        *)
            echo $(m1m2)
            ;;
    esac
}

