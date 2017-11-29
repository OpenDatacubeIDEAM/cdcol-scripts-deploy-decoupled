#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi

sudo apt-get update
sudo apt install nfs-kernel-server
sudo mkdir /dc_storage /source_storage /web_storage
sudo chown cubo:root /dc_storage /source_storage /web_storage

echo "¿Cuál es la ip publica de la web?"
read ipweb
echo "¿Cuál es la ip publica del api?"
read ipapi
sudo chmod o+w /etc/exports
cat <<EOF >>/etc/exports
/dc_storage     		$ipapi/32(rw,sync,no_subtree_check) $ipweb/32(rw,sync,no_subtree_check)
/source_storage         $ipapi/32(rw,sync,no_subtree_check) $ipweb/32(rw,sync,no_subtree_check)
/web_storage    		$ipapi/32(rw,sync,no_subtree_check) $ipweb/32(rw,sync,no_subtree_check)

EOF
sudo chmod o-w /etc/exports
sudo systemctl restart nfs-kernel-server