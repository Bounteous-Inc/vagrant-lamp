function vhelp {
  source /vagrant/php_versions.sh
  _versions=''
  for i in "${php_versions[@]}"; do
    arr=(${i// / })
    phpv=${arr[0]}
    phpn=${arr[1]}
    phpv_x=${phpv}'     '
    phpn_x=${phpn}'     '
    line="  * PHP ${phpv_x:0:6}      - alias php${phpn}"
    _versions="${_versions}${line}\n"
  done;
  text=$(sed "s/###php_versions###/${_versions}/g" /vagrant/files/welcome.txt);
  echo -e "$text"
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
      echo "<?php \$test=include('./app/etc/env.php'); print_r(\$test['db']['connection']['default']['${1}']) ?>" | php;
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

function phpRestart() {
  source /vagrant/php_versions.sh
  for i in "${php_versions[@]}"; do
    local arr=(${i// / })
    local phpn=${arr[1]}
    sudo service php-${phpn} restart
  done;
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
alias sudo='sudo '
alias www='cd /srv/www'

source /vagrant/php_versions.sh
for i in "${php_versions[@]}"; do
    arr=(${i// / })
    phpv=${arr[0]}
    phpn=${arr[1]}
    phpp=${arr[2]}
    phpa="php${phpn}='/opt/phpfarm/inst/php-${phpv}/bin/php'"
    # Make aliases
    alias $phpa;
done;
