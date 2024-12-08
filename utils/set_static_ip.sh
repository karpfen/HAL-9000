#!/bin/bash

# Set the interface name (e.g., eth0, wlan0)
INTERFACE="eth0"

# Set the static IP address, netmask, gateway, and DNS servers
IP_ADDRESS="192.168.1.100"
NETMASK="255.255.255.0"
GATEWAY="192.168.1.1"
DNS1="8.8.8.8"
DNS2="8.8.4.4"

# Backup the current network configuration file
sudo cp /etc/network/interfaces /etc/network/interfaces.bak

# Write the new network configuration
sudo cat <<EOL > /etc/network/interfaces
auto $INTERFACE
iface $INTERFACE inet static
    address $IP_ADDRESS
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers $DNS1 $DNS2
EOL

# Restart the networking service to apply changes
sudo systemctl restart networking

echo "Static IP address set to $IP_ADDRESS"
