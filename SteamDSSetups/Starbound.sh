#!/bin/bash
. ./SharedLib

clear; Title "Login Information"
printf "\n\n%s" "Enter your steam login: "; read STEAMUSERNAME
printf "%s" "Enter your steam password: "; read -s STEAMPASSWORD
printf "\n"
Separator "_"



InstallPkg lib32gcc1
InstallPkg libpng12-0
SetupSteamCMD

#----------- Create server start/stop/restart script ---------------------
EchoBold -n "  /usr/local/bin/starboundserver"
sudo bash -c "cat << EOF > /usr/local/bin/starboundserver
#!/bin/bash
case \"\\\$1\" in
start)
cd ~/Steam/steamapps/common/Starbound/linux64
./starbound_server &
;;
stop)
killall -SIGINT starbound_server
;;
restart)
$0 stop
$0 start
;;
esac
exit 0
EOF"
sudo chmod +x /usr/local/bin/starboundserver
Status

#----------- Create systemctl service ------------------------------------
EchoBold -n "  /lib/systemd/system/starboundserver.service"
USER=$(whoami)
sudo bash -c "cat << EOF > /lib/systemd/system/starboundserver.service
[Unit]
Description=Manage Starbound Server

[Service]
Type=forking
ExecStart=/usr/local/bin/starboundserver start
ExecStop=/usr/local/bin/starboundserver stop
ExecReload=/usr/local/bin/starboundserver restart
User=$USER

[Install]
WantedBy=multi-user.target
EOF"
Status

#----------- Enable systemctl service ------------------------------------
EchoBold -n "  Reload systemctl"
sudo systemctl daemon-reload
Status

EchoBold -n "  Enable starboundserver.service"
sudo systemctl enable starboundserver.service
Status

#----------- Run SteamCMD to update or install ---------------------------
Separator "_"
EchoBold "  Update or Install Starbound"
/home/$USER/steamcmd/steamcmd.sh +login $STEAMUSERNAME $STEAMPASSWORD +app_update 211820 +quit
EchoGreen "  Starbound.sh Complete!  Launching server..."
echo ""
sudo systemctl start starboundserver.service
exit 0