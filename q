#@Raspberrry
#Ensure wifi is active on RPi
#	May be blocked by rfkill - if you haven't set the country to Denmark
sudo raspi-config
# => set country to DK under LOCALIZATION OPTIONS

#Configure RPI to connect as client  to a wifi acceess point 
#		note: This does not work Eduroam
#				IE activate mobile hotspot and go on your phones wifi instead
# Configure RasPi
sudo vim /etc/wpa_supplicant/wpa_supplicant.conf

#Append this to the config file to make the rasPi connect to the specified access point:
network={
	ssid="SSID" 	#your wifi access name .. eduroam... galaxy02 for instance
	psk="PASSWORD"	#wifi password
	scan_ssid=1
}

#Reboot the Raspberry PI and you should be able to see RPi conneccts to the configured wifi access point 
iwconfig

#And you can see the IP address assigned  to the RPi by the access point by running 
ifconfig


#Pinging still doesn't work -- ie ping dr.dk is not possible
# Why?
# Because we have configured both the RPi wifi interface & the RPi Ethernet interface
#	therefore the RPi doesn't know which interface to use for internet access 
#		and will try to use the ethernet interface
#Run:
ip route show
#
default via 10.0.0.1 dev eth0 src 10.0.0.10 metric 202 #eth0 is configured to route via 10.0.0.1, 

default via 192.168.0.1 dev wlan0 proto dhcp src 192.168.0.150 metric 303 #wlan  ie the wifi interface  is configured to route via 192.168.0.1
10.0.0.0/24 dev eth0 proto dhcp scope link src 10.0.0.10 metric 202
192.168.0.0/24 dev wlan0 proto dhcp scope link src 192.168.0.150 metric 303


#the 'metric' value determines which gateway the RPi uses to route external (internet) traffic
#	In other words, we need to make sure that the wifi interface has the lowest 'metric'-value
#How to do this?
#	Delete the route and create it again
sudo ip route del default via 192.168.0.1
sudo ip route add default via 192.168.0.1 dev wlan0 proto static metric 10

#and now run and observe the change in the routing table   - The wireless should now have the lowest metric, and you should be able to ping dr.dk
ip route show


#####################	Configure RPi as wifi access point		#########################
#Note: this is conflicting to the previous exercise where the RPi acted as a wifi client 
#	With only one wifi interface it is not possible to act as both as an accesspoint  and  a client at the same time
#	Note:
#		Setting up the Rpi as a wifi access point means that we define 
#			the ip address of the access point 
#			& the ip addresss that are issued by the access point to wifi clients connecting to the wifi access point 


#1: Disable the current wifi client configuration in wpa_supplicant
sudo vim  /etc/wpa_supplicant/wpa_supplicant.conf

#2 outcomment what you did before

#network={
#	ssid="SSID" 	#your wifi access name .. eduroam... galaxy02 for instance
#	psk="PASSWORD"	#wifi password
#	scan_ssid=1
#}

#3.  For the wifi acccess point we will use the subnet  192.168.10.0/24

#a) Configure the RPI IP address on the wifi device
#		this ip address will then become the routing  address(ie gateway) for he connected wifi clients

sudo vim /etc/dhcpcd.conf

#and add this
interface wlan0
	static ip_address=192.168.10.1/24
	nohook wpa_supplicant

#b) Install and configure  the access point (ap) package
sudo apt install hostapd

#edit the config file (new file):
sudo vim /etc/hostapd/hostapd.conf
#add this



country_code=DK
interface=wlan0
ssid=LEO1_TEAM_02
hw_mode=a
channel=40
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=embeddedlinux
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP

#Note:
# 	ssid= THENAMEOFTHEWIFIYOUWANTTOGIVEIT
#	hw-mode=g 			- 2.4 GHz
#	hw-mode=a 			- 5.0 GHz (Default)

#For 2.4 GHz the channels 1-13 are available in Denmark3. They are however overlapping and not all
#devices accept channel 12 and 13. You should therefore only use the channels: 1, 6, 11.
#For 5 GHz the channels do not have the same problem of overlapping as on 2.4 GHz. There are
#quite a few channels available, but most of them require Dynamic Frequency Selection (DFS) to
#mitigate interference with 5 GHz radars. For now to make things simple use the channels4: 36, 40,
#44, 48.


#b) Run these commands to start the hostapd service:
#The configuration will make the RPi broadcast the wifi network SSID and allow connections.
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd

#c)install and  DHCP service  
#The problem right now is that the clients cnanot connect successfully  unless an ip is issued to the wifi client 
#		via the dhcp . 

sudo apt install dnsmasq

#d) Create a backup of the config file and create a new empty file
#		it has a very long config file by default... no need
sudo mv /etc/dnsmasq.conf /etc/gnsmasq.conf.orig
sudo vim /etc/dnsmasq.conf

#add this to the file:
interface=wlan0
dhcp-range=192.168.10.150,192.168.10.199,255.255.255.0,1h
domain=wlan
address=/leo1_ap.wlan/192.168.10.1

#5 - Reboot the RPi to let the configs take effect
#		ie the rpi access point is visible for clients to connect
sudo reboot

#6 Try connec to the WIFI
#	Notice you get assigned a IP address  from 192.168.10.150-192.168.10.199

#SSH into the PI o
# 	And check the webserver that was created  before:
http//192.168.10.1

##############			3.3 Routing RPi wifi access traffic 		##################3
# enable RPI wifi access to route traffic from a connected wifi client  to the internet via the ethernet port


#Use iptables to handle the routing 
sudo apt install iptables

#same as we did in M02_EX6.6
#		but this time do it on @RaspberryPi
#	Route traffic from WIFI CLIENTS connected to wlan0 onto the ETH0 INTERFACE
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE




