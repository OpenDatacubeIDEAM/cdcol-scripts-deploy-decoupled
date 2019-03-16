#!/bin/bash

if [[ $(id -u) -eq 0 ]] 
then 
cat <<- EOF
This script must not be excecuted as root \
or using sudo (althougth the user must be \
sudoer and password will be asked in some steps)
EOF
exit 1
fi

# The IPAdrress and Mask of the Webserver
# Ex: 192.168.2.105/255.255.255.0
# Ex: 192.168.2.105/16
web_ip=$1

# Workers Network Identifier and Mask
# Ex: 192.168.2.0/255.255.255.0
# Ex: 192.168.2.0/16
workers_net=$2

echo "Web IPAddress: $web_ip"
echo "Workers Network: $workers_net"

echo "Setting up nfs ..."
sudo apt-get update
sudo apt install nfs-kernel-server
sudo mkdir /dc_storage /source_storage /web_storage
sudo chown cubo:root /dc_storage /source_storage /web_storage

sudo chmod o+w /etc/exports
cat <<EOF >>/etc/exports
/dc_storage     		$workers_net(rw,sync,no_subtree_check) $web_ip(rw,sync,no_subtree_check)
/source_storage         $workers_net(rw,sync,no_subtree_check) $web_ip(rw,sync,no_subtree_check)
/web_storage    		$workers_net(rw,sync,no_subtree_check) $web_ip(rw,sync,no_subtree_check)

EOF
sudo chmod o-w /etc/exports
sudo systemctl restart nfs-kernel-server