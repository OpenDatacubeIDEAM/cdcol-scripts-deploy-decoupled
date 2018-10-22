#!/bin/bash

if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi

sudo apt-get update

IP=`hostname -I | awk '{ print $1 }'`
echo IP
USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
PASSWORD_AIRFLOW='Cubo2017*'


sudo apt install redis-server
sudo sed -i "s%bind .*%bind $IP%" "/etc/redis/redis.conf"
sudo service redis restart

sudo -u postgres createdb airflow
sudo -u postgres createuser airflow
sudo -u postgres psql airflow -c "alter user airflow with encrypted password '$PASSWORD_AIRFLOW';"
sudo -u postgres psql airflow -c "grant all privileges on database airflow to airflow;"
sudo systemctl restart postgresql.service

