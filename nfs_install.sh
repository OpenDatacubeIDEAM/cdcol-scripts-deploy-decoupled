#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi


sudo apt install nfs-kernel-server
sudo mkdir /dc_storage /source_storage /web_storage
sudo chown cubo:root /dc_storage /source_storage /web_storage
sudo chown cubo:root /source_storage
sudo chown cubo:root /web_storage
ed 