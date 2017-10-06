#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi


sudo apt install -y openssh-server postgresql-client-9.5 postgresql-contrib-9.5 pgadmin3 git wget htop imagemagick ffmpeg nginx|| exit 1

