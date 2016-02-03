#!/bin/bash

SudoWriteLineIfNotThere() { su -c "grep -q -F '$1' $2 || echo '$1' >> $2" root; }

clear
echo "This script requires sudo permission"
LATESTKERNEL=`apt-cache search linux-image | grep 'linux-image' | grep -v 'dbg' | grep -v 'meta' | tail -1`
sudo bash -c "cat >> /etc/apt/preferences << EOF
Package: *
Pin: release o=Debian,a=stable-proposed-updates
Pin-Priority: 102
EOF"
SudoWriteLineIfNotThere "deb http://ftp.us.debian.org/debian stable-proposed-updates main" "/etc/apt/sources.list"

clear
echo "Updating repositories.  Please wait..."
sudo apt-get update 1>/dev/null
printf "\n\n"
echo "This script will now proceed to upgrade"
echo "Debian from stable to stable-proposed-updates."
echo "Version: $LATESTKERNEL"
printf "%s" "Does this appear correct?  Y/N: "
read CONFIRM
if [ "${CONFIRM,,}" != "y" ]; then
  echo "Exiting..."
  exit 0
fi



clear
sudo apt-get install `echo "$LATESTKERNEL" | cut -d " " -f1`
sudo apt-get install firmware-linux-nonfree



