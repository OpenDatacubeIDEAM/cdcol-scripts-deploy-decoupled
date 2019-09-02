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

sudo apt-get update -qq -y
sudo apt install -qq -y \
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

