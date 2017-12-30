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
      php7 bin/magento cache:flush;
      ;;
    *)
      echo $(m1m2);
      ;;
  esac
}
function getMSetting {
  case $(m1m2) in
    M1)
      grep "<${1}>" app/etc/local.xml | cut -d'[' -f3 | cut -d']' -f1;
      ;;
    M2)
      echo "<?php \$test=include('./app/etc/env.php'); print_r(\$test['db']['connection']['default']['${1}']) ?>" | php7;
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
function templateHelp  {
  case $(m1m2) in
    M1)
      echo "UPDATE core_config_data SET value=${1:-1} where path IN('dev/debug/template_hints', 'dev/debug/template_hints_blocks');" | connectDb;
      cac;
      ;;
    M2)
      echo "Not yet supported for M2 - sorry"
      ;;
    *)
      echo $(m1m2)
      ;;
  esac
}
function err           { clear; cat "var/report/${1:-$(ls -t var/report/* | head -1 | cut -d'/' -f3)}" ; echo ""; }
function xdebug {
  state=$([ ${1:-1} == 0 ] && echo ";");
  echo $([ ${1:-1} == 0 ] && echo "Disabling" || echo "Enabling")" X-Debug:"
  services=$(ls -a /etc/init.d/ | grep php);
  ini_files=$(ls -df /opt/phpfarm/inst/php-*/lib/php.ini);
  for ini in ${ini_files}
    do sudo sed -i "s/[;]*zend_extension=xdebug.so/${state}zend_extension=xdebug.so/g" ${ini};
  done;
  for svc in ${services}
    do echo -n "  * Restarting ${svc}... " && sudo service ${svc} restart > null && echo "done."
  done;
}
alias ll='ls -al'
alias lh='ls -alh'
alias mem='free | awk '\''/Mem/{printf("Memory used: %.2f%"), $3/$2*100} /buffers\/cache/{printf(", buffers: %.2f%\n"), $4/($3+$4)*100}'\'''
alias php5.6='/opt/phpfarm/inst/php-5.6.20/bin/php'
alias php7='/opt/phpfarm/inst/php-7.0.6/bin/php'
alias php7.1='/opt/phpfarm/inst/php-7.1.12/bin/php'
alias help='cat /vagrant/files/help.txt'
