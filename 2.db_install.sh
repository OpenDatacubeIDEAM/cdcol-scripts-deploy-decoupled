#!/bin/bash

if [[ $(id -u) -eq 0 ]] ; then 
	echo "This script must  not be excecuted \
	as root or using sudo(althougth the user must \
	be sudoer and password will be asked in some steps)" ; 
	exit 1 ; 
fi

# Configuracion
USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
PASSWORD_AIRFLOW='cubocubo'
IP=`hostname -I | awk '{ print $1 }'`
echo "=> La direccion IP actual es: $IP"

echo "=> Instalacion de Paquetes ..."

sudo apt-get update -y
sudo apt install -y \
	openssh-server \
	postgresql-9.5 \
	postgresql-client-9.5 \
	postgresql-contrib-9.5 \
	libhdf5-serial-dev \
	hdf5-tools \
	pgadmin3 \
	postgresql-doc-9.5 \
	libhdf5-doc \
	git \
	wget \
	htop \
	rabbitmq-server || exit 1

echo "=> Creacion Base de Datos datacube ..."
echo "=> Usuario de la Base de Datos: $USUARIO_CUBO"
echo "=> Password de la Base de Datos: $PASSWORD_CUBO"

sudo -u postgres psql postgres<<EOF
create user $USUARIO_CUBO with password '$PASSWORD_CUBO';
alter user $USUARIO_CUBO createdb;
alter user $USUARIO_CUBO createrole;
alter user $USUARIO_CUBO superuser;
EOF

createdb datacube

echo "=> Creacion Base de Datos ideam ..."

sudo -u postgres psql postgres<<EOF
CREATE DATABASE ideam;
\c ideam
CREATE USER portal_web with password 'CDCol_web_2016';
EOF

echo "=> Instalacion de Redis ..."

sudo apt install redis-server
sudo sed -i "s%bind .*%bind $IP%" "/etc/redis/redis.conf"
sudo service redis restart

echo "=> Creacion Base de Datos airflow ..."
echo "=> Usuario de la Base de Datos: airflow"
echo "=> Password de la Base de Datos: $PASSWORD_AIRFLOW"

sudo -u postgres createdb airflow
sudo -u postgres createuser airflow
sudo -u postgres psql airflow -c "alter user airflow with encrypted password '$PASSWORD_AIRFLOW';"
sudo -u postgres psql airflow -c "grant all privileges on database airflow to airflow;"
sudo systemctl restart postgresql.service

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

echo "=> Set listen_addresses = 'localhost' to '*' in '/etc/postgresql/9.5/main/postgresql.conf' "
sed -i "s/^#listen_addresses = .*/listen_addresses = '*'/g" /etc/postgresql/9.5/main/postgresql.conf
echo "=> Add line 'host    all             all             $Network\/$MaskCIDR          md5' to '/etc/postgresql/9.5/main/pg_hba.conf' "
sudo sed -i '/host    all             all             ::1\/128                 md5/ a host    all             all             $Network\/$MaskCIDR          md5' /etc/postgresql/9.5/main/pg_hba.conf

sudo systemctl restart postgresql.service
