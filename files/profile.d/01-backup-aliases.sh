# Backup / Restore functions:
function backupMysql {
    export MYSQL_PWD='root'
    databases=`mysql -uroot -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`
    for db in $databases; do
        case ${db} in
           'information_schema' | 'performance_schema' | 'sys' | 'mysql' | 'test' | _*)
            # skip it
            ;;
        *)
            echo "Dumping database: $db"
            mysqldump -uroot --databases $db | gzip > /srv/backup/mysql/$db.sql.gz
            ;;
        esac
    done
    pt-show-grants -uroot -proot | gzip > /srv/backup/mysql/mysql_users.sql.gz
    export MYSQL_PWD=''
}

function backupWebconfig {
    if [ -f /srv/backup/webconfig/config.tar ]; then
        rm -f /srv/backup/webconfig/config.tar
    fi
    tar -cf /srv/backup/webconfig/config.tar /etc/apache2/sites-available/200-* /etc/apache2/sites-enabled/200-* /etc/apache2/ssl
}

function restoreMysql {
    export MYSQL_PWD='root'
    databases=`ls -1 /srv/backup/mysql/*.sql.gz`
    for db in $databases; do
        echo "Importing $db ..."
        zcat $db | mysql -u root
    done
    export MYSQL_PWD=''
}

function restoreWebconfig {
    if [ -f /srv/backup/webconfig/config.tar ]; then
        cd /
        sudo tar -xf /srv/backup/webconfig/config.tar
        cd -
    else
        echo "Error - no /srv/backup/webconfig/config.tar file is present. You need to execute backupWebconfig first."
    fi
}
