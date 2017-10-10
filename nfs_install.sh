#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi

sudo apt-get update
sudo apt install nfs-kernel-server
sudo mkdir /dc_storage /source_storage /web_storage
sudo chown cubo:root /dc_storage /source_storage /web_storage

echo "¿Cuál es la ip publica del servidor del web?"
read $ipweb

sudo bash -c 'cat <<EOF >>/etc/exports
/dc_storage     		192.168.0.0/16(rw,sync,no_subtree_check) $ipweb/32(rw,sync,no_subtree_check)
/source_storage         192.168.0.0/16(rw,sync,no_subtree_check) $ipweb/32(rw,sync,no_subtree_check)
/web_storage    		192.168.0.0/16(rw,sync,no_subtree_check) $ipweb/32(rw,sync,no_subtree_check)

EOF'
sudo systemctl restart nfs-kernel-server