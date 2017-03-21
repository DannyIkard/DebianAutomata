#!/bin/bash

USER=$(whoami)

sudo apt-get update
sudo apt-get install tightvncserver
touch $HOME/.Xresources


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

sudo bash -c "cat << EOF > \\\$HOME/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startxfce4
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r \\\$HOME/.Xresources ] && xrdb \\\$HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
EOF"

#----------- Enable systemctl service ------------------------------------
sudo systemctl daemon-reload
sudo systemctl enable tightvncserver.service

/usr/local/bin/tightvncserver start

