#!/bin/bash

USER=$(whoami)


AddIfDoesntExist(){
  if ! cat $2 | grep "$1"; then
    sudo su -c "echo \"$1\">>$2" root
  fi
}


if [ "$USER" != "root" ]; then
  echo " This script must be run as root."
  exit 1
fi


apt-get update
apt-get install php mysql-server php-pear php-mysql php-gd zoneminder
mysql -uroot -p < /usr/share/zoneminder/db/zm_create.sql
mysql -uroot -p -e "grant all on zm.* to 'zmuser'@localhost identified by 'zmpass';"
mysqladmin -uroot -p reload
chmod 740 /etc/zm/zm.conf
chown root:www-data /etc/zm/zm.conf
systemctl enable zoneminder.service
adduser www-data video
systemctl start zoneminder.service
a2enmod cgi
a2enmod rewrite
a2enconf zoneminder
nano /etc/php/7.0/apache2/php.ini
AddIfDoesntExist "date.timezone = America/New_York" "/etc/php/7.0/apache2/php.ini"
exit 0