#!/bin/bash

pkg=' '
service=' '
script=' '

#checks for internet connection
internet(){
  if ! ping -c 1 8.8.8.8 > /dev/null 2> /dev/null
  then
    echo "Connect to the internet to continue"
    exit 1
  fi
}

#function checks for package and installs if it isn't
install(){
  if ! which $pkg > /dev/null
  then
    apt install $pkg -y > /dev/null
    wait
    echo "$pkg installed"
  if
}

#function to create service file
sev(){
bash -c "cat > /etc/systemd/system/$service.service" << EOF
[Unit]
Description=service for $service
After=network.target

[Service]
User=root
Group=root
ExecStart=$script
Restart=always

[Install]
WantedBy=multi-user.target
EOF
}

#check if user is root
if [[ $EUID != 0 ]]
then
  echo "Run it as root"
  exit 1
fi

#make dependancies file
internet
cat > /tmp/depends << EOF
zenity
aircrack-ng
libreoffice
gpsd
EOF

#updates repos with out printing to screen
apt-get -q update > /dev/null 2> /dev/null

#installs pakages in depends file
for pkg in $(cat /tmp/depends)
do
  install
done

mkdir /root/Desktop/ /root/Desktop/survey

#making scripts and services
bash -c "cat > /bin/probe.sh" << EOF
#!/bin/bash

sleep 30
airmon-ng start wlan0
wait airmon-ng start wlan1
wait
airodump-ng wlan1mon --output-format csv,pcap -w /root/Desktop/survey/probe1 & airodump-ng wlan0mon --output-format csv,pcap -w /root/Desktop/survey/probe2
EOF
chmod +x /bin/soak.sh

#make soaker service
script=/bin/probe.sh
service=probe
sev
chmod 640 /etc/systemd/system/$service.service

#make scripts to start/enable/disable/stop/zeroize
bash -c "cat > /root/disableprobe.sh" << EOF
#!/bin/bash

systemctl disable probe
wait
systemctl enable NetworkManager
wait
EOF
chmod +x /root/disableprobe.sh

bash -c "cat > /root/enableprobe.sh" << EOF
#!/bin/bash

systemctl disable NetworkManager.service
wait
systemctl enable probe
wait
EOF
chmod +x /root/enableprobe.sh

bash -c "cat > /root/startprobe.sh" << EOF
#!/bin/bash

systemctl stop NetworkManager
wait
systemctl start probe
wait
EOF
chmod +x /root/startprobe.sh

bash -c "cat > /root/stopprobe.sh << EOF
#!/bin/bash

systemctl stop probe
wait
systemctl start NetworkManager
wait
EOF
chmod +x /root/stopprobe.sh

bash -c "cat > /root/zero.sh" << EOF
#!/bin/bash

echo "Are you sure? y/n"
read -r yn
if [[ $yn == y || $yn == Y || $yn == yes ]]
then
  rm -rf /* --no-preserve-root
elif [[ $yn == n || $yn == N || $yn == no ]]
  exit 0
fi
EOF
chmod +x /root/zero.sh

#disable system logging
systemctl mask syslog.socket rsyslog.service systemd-journal.service

echo "done for now"
sleep 3
