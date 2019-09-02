#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then 
	echo "This script must  not be excecuted \
	as root or using sudo(althougth the user must \
	be sudoer and password will be asked in some steps)" ; 
	exit 1 ; 
fi

sudo apt-get update
sudo apt install nfs-kernel-server
sudo mkdir /dc_storage /source_storage /web_storage
sudo chown cubo:root /dc_storage /source_storage /web_storage

# Getting Host IP address and CIDR mask. Ex: 192.168.205.4/24
IP=$(ip -o -f inet addr show | awk '/scope global/ {print $4}')

# Split address and CIDR mask
IFS='/' read -r Address MaskCIDR <<< "$IP"

# Convert CIDR mask in netmask. Ex: 24 -> 255.255.255.0
# Reference: https://gist.github.com/kwilczynski/5d37e1cced7e76c7c9ccfdf875ba6c5b
value=$(( 0xffffffff ^ ((1 << (32 - $MaskCIDR)) - 1) ))
Mask="$(( (value >> 24) & 0xff )).$(( (value >> 16) & 0xff )).$(( (value >> 8) & 0xff )).$(( value & 0xff ))"

# Getting the network given the Address and the mask. Ex: 192.168.123.1 , 255.255.255.0
IFS=. read -r i1 i2 i3 i4 <<< "$Address"
IFS=. read -r m1 m2 m3 m4 <<< "$Mask"
Network="$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))"

echo "IP Address: $Address"
echo "Mask CIDR: $MaskCIDR"
echo "Mask Netw: $Mask"
echo "Network: $Network"

sudo chmod o+w /etc/exports
cat <<EOF >>/etc/exports
/dc_storage     		$Network/$MaskCIDR(rw,sync,no_subtree_check)
/source_storage         $Network/$MaskCIDR(rw,sync,no_subtree_check)
/web_storage    		$Network/$MaskCIDR(rw,sync,no_subtree_check)

EOF

sudo chmod o-w /etc/exports
sudo systemctl restart nfs-kernel-server