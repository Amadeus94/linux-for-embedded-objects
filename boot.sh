#!/bin/bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

#Make it executable via 
#	chmod 755 /home/pi/bin/boot.sh

#Add the script to /etc/rc.local
#sudo vim /etc/rc.local

#add this to end of file
# sudo sh /home/pi/bin/boot.sh

#reboot raspi:
