#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi


sudo apt install -y openssh-server postgresql-9.5 postgresql-client-9.5 postgresql-contrib-9.5 libhdf5-serial-dev hdf5-tools pgadmin3 postgresql-doc-9.5 libhdf5-doc git wget htop rabbitmq-server || exit 1

