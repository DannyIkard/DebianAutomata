#!/bin/bash
. ./SharedLib
clear

#----------- Get steam username and password for SteamCMD login ----------
sudo printf "%s" ""
printf "\n\n%s" "Enter your steam login: "; read STEAMUSERNAME
printf "%s" "Enter your steam password: "; read -s STEAMPASSWORD

DSACCOUNT="`cat DSACCOUNT 2>/dev/null`"
printf "\n\n%s\n" "You can leave the following blank and just press return if you"
echo "choose not to use a workshop collection or dedicated server account"
printf "\n\n%s\n" "Dedicated game server account ID - You can get this"
echo "from https://steamcommunity.com/dev/managegameservers"
read -e -p "Enter your dedicated server account ID: " -i "$DSACCOUNT" DSACCOUNT
echo "$DSACCOUNT" >DSACCOUNT

WORKSHOPCOLLECTION="`cat WORKSHOPCOLLECTION 2>/dev/null`"
printf "\n\n%s\n" "Workshop Collection - Once you make a collection"
echo "for Garry's Mod the ID will be in the URL.  Something like 123456789"
read -e -p "Enter your workshop collection ID: " -i "$WORKSHOPCOLLECTION" WORKSHOPCOLLECTION
echo "$WORKSHOPCOLLECTION" >WORKSHOPCOLLECTION

AUTHKEY="`cat AUTHKEY 2>/dev/null`"
printf "\n\n%s\n" "Authkey - Your authkey can be created and obtained"
echo "from https://steamcommunity.com/dev/apikey"
read -e -p "Enter your authkey: " -i "$AUTHKEY" AUTHKEY
echo "$AUTHKEY" >AUTHKEY


#----------- Install dependencies and directories ------------------------
printf "\n%s" "Enter this machines root "
#SudoWriteLineIfNotThere "deb http://ftp.us.debian.org/debian/ testing main contrib non-free" "/etc/apt/sources.list"
sudo apt-get update
#sudo apt-get -y -t testing libc6
sudo apt-get -y install lib32gcc1 libpng12-0 lib32stdc++6 lib32tinfo5 screen
mkdir -p ~/Steam/steamapps/common/Starbound/ 2>/dev/null
cd ~/steamcmd



SetupSteamCMD



#----------- Create server start/stop/restart script ---------------------
sudo bash -c "cat << EOF > /usr/local/bin/garrysmodserver
#!/bin/bash
case \"\\\$1\" in
start)
cd /home/$USER/Steam/steamapps/common/GarrysModDS
bash srcds_startupscript.sh
;;
stop)
killall -SIGINT srcds_linux
sleep 7
killall -SIGTERM srcds_linux
sleep 1
screen -X -S "GMODDS" quit
;;
restart)
killall -SIGINT srcds_linux
;;
esac
exit 0
EOF"
sudo chmod +x /usr/local/bin/garrysmodserver



#----------- Create systemctl service ------------------------------------

sudo bash -c "cat << EOF > /lib/systemd/system/garrysmodserver.service
[Unit]
Description=Manage Garrys Mod Server

[Service]
Type=forking
ExecStart=/usr/local/bin/garrysmodserver start
ExecStop=/usr/local/bin/garrysmodserver stop
ExecReload=/usr/local/bin/garrysmodserver restart
User=$USER

[Install]
WantedBy=multi-user.target
EOF"



#----------- Enable systemctl service ------------------------------------
sudo systemctl daemon-reload
sudo systemctl enable garrysmodserver.service



#----------- Run SteamCMD to update or install ---------------------------
#--Garry's Mod                               =4020
#--Counter-Strike: Source Dedicated Server   =232330
#--Team Fortress 2                           =440
#--Half-Life 2: Dedicated Server             =232370
./steamcmd.sh +login anonymous +app_update 4020 +app_update 232330 +app_update 440 +app_update 232370 +quit

#--Half-Life 2: Episode One                  =380
#--Half-Life 2: Episode Two                  =420
./steamcmd.sh +login $STEAMUSERNAME $STEAMPASSWORD +app_update 380 +app_update 420 +quit



#----------- Create startup script ------------------------------------
USER=$(whoami)
sudo bash -c "cat << EOF > /home/$USER/Steam/steamapps/common/GarrysModDS/srcds_startupscript.sh
#!/bin/bash
MAP=\"gm_flatgrass\"
MAXPLAYERS=\"12\"
#---- You can get this from https://steamcommunity.com/dev/managegameservers
DSACCOUNT=\"$DSACCOUNT\"
#---- Once you make a collection for Garry's Mod the ID will be in the URL.  Something like 123456789
WORKSHOPCOLLECTION=\"$WORKSHOPCOLLECTION\"
#---- Your authkey can be created and obtained from https://steamcommunity.com/dev/apikey
AUTHKEY=\"$AUTHKEY\"
screen -A -m -d -S GMODDS /home/$USER/Steam/steamapps/common/GarrysModDS/srcds_run -game garrysmod +maxplayers \\\$MAXPLAYERS +sv_setsteamaccount \\\$DSACCOUNT +host_workshop_collection \\\$WORKSHOPCOLLECTION -authkey \\\$AUTHKEY +map \\\$MAP
EOF"




#----------- Create readme ------------------------------------
sudo bash -c "cat << EOF > /home/$USER/Desktop/GMOD_ReadMe.txt
To start/stop/restart:
     sudo systemctl start/stop/restart garrysmodserver.service

To enter the console:
     screen -x GMODDS
     Hit CTRL +A +D to leave the console and leave the server running

To see what's running on a system type 'top' in a console.  Hit ctrl-c to exit it.
EOF"



#----------- Run SteamCMD to update or install ---------------------------
printf "\n\n%s\n" "You can edit the startup script in the garrys mod folder at:"
echo "/home/$USER/Steam/steamapps/common/GarrysModDS/srcds_startupscript.sh"
echo "You can enter the console with 'screen -x GMODDS' and exit the console "
echo "by pressing 'CTRL +A +D'"
echo "You can also stop, start and restart the server with systemctl commands"
echo "such as 'sudo systemctl start garrysmodserver.service'"
echo ""
exit 0