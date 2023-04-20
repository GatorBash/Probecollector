#!/bin/bash

pkg=' '
service=' '
script=' '

if [[ $UID != 0 ]]
then
  echo "Run it as root"
  exit 1
fi

internet(){
  if ! ping -c 1 8.8.8.8
  then
    echo "Connect to the internet"
    exit 1
  fi
}

install(){
  if ! which $pkg > /dev/null
  then
    apt install $pkg -y > /dev/null 2> /dev/null
    wait "$pkg installed"
}

internet

apt update -y && apt full-upgrade -y

cat > /tmp/installs << EOF
aircrack-ng
libreoffice
gpsd
zenity
EOF

for pkg in $(cat /tmp/installs)
do
  
  
