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
#----------- Create server start/stop/restart script ---------------------
sudo bash -c "cat << EOF > /usr/local/bin/tightvncserver
#!/bin/bash
PATH=\"\\\$PATH:/usr/bin/\"
DISPLAY=\"1\"
DEPTH=\"24\"
GEOMETRY=\"1600x900\"
OPTIONS=\"-depth \\\${DEPTH} -geometry \\\${GEOMETRY} :\\\${DISPLAY}\"

case \"\\\$1\" in
start)
/usr/bin/vncserver \\\${OPTIONS}
;;

stop)
/usr/bin/vncserver -kill :\\\${DISPLAY}
;;

restart)
\\\$0 stop
\\\$0 start
;;
esac
exit 0

EOF"
sudo chmod +x /usr/local/bin/tightvncserver



#----------- Create systemctl service ------------------------------------

sudo bash -c "cat << EOF > /lib/systemd/system/tightvncserver.service
[Unit]
Description=Manage TightVNC Server

[Service]
Type=forking
ExecStart=/usr/local/bin/tightvncserver start
ExecStop=/usr/local/bin/tightvncserver stop
ExecReload=/usr/local/bin/tightvncserver restart
User=$USER

[Install]
WantedBy=multi-user.target
EOF"




#----------- Create systemctl service ------------------------------------

sudo bash -c "cat << EOF > /home/$USER/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startxfce4
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r \\$HOME/.Xresources ] && xrdb \\$HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
EOF"

#----------- Enable systemctl service ------------------------------------
sudo systemctl daemon-reload
sudo systemctl enable tightvncserver.service

/usr/local/bin/tightvncserver start

