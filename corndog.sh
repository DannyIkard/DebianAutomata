#!/bin/bash

# This script is a connection watchdog for Debian Stretch when using Deluge-GTK and a VPN.
# It uses Network Manager and the ip command to monitor and control the connections.
# It uses iptables to help prevent leaks outside the VPN.
# So make sure you have all of that installed.
# You can check the names of your network connections in the GUI or by using "nmcli connection show"
# You can check the names of the interface names with the command "ip addr show"


# Below is the name of the ethernet connection used
NMETH="Ethernet" # Name of the ethernet connection in Network Manager
IPETH="enp4s0" # Interface that indicates the hardwired LAN IP

# Below is the name of the VPN connection used
NMVPN="VPN" # Name of the VPN connection in Network Manager
IPVPN="tun0" # Interface that indicates the VPN LAN IP

# Below is the name of the user to run deluge
DELUGEUSER="user"




LOGTRIM=0
LOG=/var/log/corndog.log
CONNOK=0
ONBOARDETHIP=""
VPNETHIP=""
VPNWANIP=""
echo "`date` - CornDog Started" >>$LOG

iptables -A OUTPUT -m owner --gid-owner $DELUGEUSER -o lo -j ACCEPT
iptables -A OUTPUT -m owner --gid-owner $DELUGEUSER \! -o $IPVPN -j REJECT


function KillDeluge(){
	echo "`date` - Connection error.  Stopping Deluge." >>$LOG
	killall -SIGINT deluged
#	killall -SIGINT deluge-web
#	killall -SIGINT "/usr/bin/python"
};

while true; do
	ONBOARDETHIP=""
	VPNETHIP=""
	VPNWANIP=""

	ReconCount=0
	while [ "$ONBOARDETHIP" == "" ]; do
		ONBOARDETHIP="`ip addr show $IPETH | grep inet | grep -v inet6 | awk '{print $2}'`"
		if [ "$ONBOARDETHIP" == "" ]; then
			KillDeluge
			echo "`date` - WAN down, starting NM 'Any Ethernet'..."   >>$LOG
			nmcli --ask -p con up "Any Ethernet" 2>>$LOG
			sleep 10
			ReconCount=$((ReconCount+1))
			CONNOK=0
		fi
		if [ "$ReconCount" -gt 10 ]; then
			echo "`date` - Attempts to start WAN connection have failed.  Rebooting..." >>$LOG
			#reboot
		fi
	done

	ReconCount=0
	while [ "$VPNETHIP" == "" ]; do
		VPNETHIP="`ip addr show $IPVPN | grep inet | grep -v inet6 | awk '{print $2}'`"
		if [ "$VPNETHIP" == "" ]; then
			KillDeluge
			echo "`date` - VPN down, starting NM '$NMVPN'..." >>$LOG
			nmcli --ask -p con up "$NMVPN" 2>>$LOG
			sleep 10
			ReconCount=$((ReconCount+1))
			CONNOK=0
		fi
		if [ "$ReconCount" -gt 10 ]; then
			echo "`date` - Attempts to start VPN connection have failed.  Rebooting..." >>$LOG
			#reboot
		fi
	done

	ReconCount=0
	while [ "$VPNWANIP" == "" ]; do
		VPNWANIP="`dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null`";
		if [ "$VPNWANIP" == "" ]; then
			KillDeluge
			echo "`date` - VPN has no WAN IP, restarting NM '$NMVPN'..." >>$LOG
			nmcli --ask -p con down "$NMVPN" 2>>$LOG
			sleep 2
			nmcli --ask -p con up "$NMVPN" 2>>$LOG
			sleep 10
			ReconCount=$((ReconCount+1))
			CONNOK=0
		fi
		if [ "$ReconCount" -gt 10 ]; then
			echo "`date` - Attempts to get VPN IP have failed.  Rebooting..." >>$LOG
			#reboot
		fi
	done

	if [[ "$ONBOARDETHIP" != "" && "$VPNETHIP" != "" && "$VPNWANIP" != "" ]]; then
		if [ "$CONNOK" == 0 ]; then
			echo "`date` - OK - $ONBOARDETHIP -> $VPNETHIP -> $VPNWANIP" >>$LOG
			wget --read-timeout=0.0 --waitretry=5 --tries=40 https://freedns.afraid.org/dynamic/update.php?Y0tzQnAwdEgza0JvZnlRVjlaak46MTA2ODI1Nzc= -O /dev/null
			echo "`date` - Starting deluge" >>$LOG
			su -c "deluged" $DELUGEUSER
			sleep 5
      su -c "deluge-console \"config -s listen_interface $VPNETHIP\"" $DELUGEUSER >>$LOG
			CONNOK=1
		fi
		sleep 30
	else
		KillDeluge
		sleep 30
	fi
	LOGTRIM=$((LOGTRIM+1))
	if [ "$LOGTRIM" -gt 120 ]; then
		LOGTRIM=0
		LOG="corndog.log"
		LOGLINES="`wc -l /var/log/$LOG | cut -d ' ' -f1`"
		if [ "$LOGLINES" -gt 500 ]; then
			TRIMLINES="$((LOGLINES-499))"
			tail -n +$TRIMLINES "/var/log/$LOG" > "/dev/shm/$LOG" && mv "/dev/shm/$LOG" "/var/log/$LOG"
		fi
	fi

	echo "$ONBOARDETHIP" >/dev/shm/ONBOARDETHIP
	echo "$VPNETHIP" >/dev/shm/VPNETHIP
	echo "$VPNWANIP" >/dev/shm/VPNWANIP
done

exit 1
