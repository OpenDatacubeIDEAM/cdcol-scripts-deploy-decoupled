#!/bin/bash

# This script will
# 1. Install Postgres Database Manager System
# 2. Set the 'datacube' database
# 3. Set the 'airflow' database
# 4. Install redis


if [[ $(id -u) -eq 0 ]] 
then 
cat <<EOF
This script must not be excecuted as root \
or using sudo (althougth the user must be \
sudoer and password will be asked in some steps)
EOF
exit 1
fi

IP=`hostname -I | awk '{ print $1 }'`
echo $IP
USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
PASSWORD_AIRFLOW='cubocubo'

sudo apt-get update
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
	rabbitmq-server \
	|| exit 1

# Create 'cubo' user
sudo -u postgres psql postgres<<EOF
create user $USUARIO_CUBO with password '$PASSWORD_CUBO';
alter user $USUARIO_CUBO createdb;
alter user $USUARIO_CUBO createrole;
alter user $USUARIO_CUBO superuser;
EOF

createdb datacube

sudo -u postgres psql postgres<<EOF
CREATE DATABASE ideam;
\c ideam
CREATE USER portal_web with password 'CDCol_web_2016';
EOF

sudo apt install redis-server
sudo sed -i "s%bind .*%bind $IP%" "/etc/redis/redis.conf"
sudo service redis restart

sudo -u postgres createdb airflow
sudo -u postgres createuser airflow
sudo -u postgres psql airflow -c "alter user airflow with encrypted password '$PASSWORD_AIRFLOW';"
sudo -u postgres psql airflow -c "grant all privileges on database airflow to airflow;"
sudo systemctl restart postgresql.service

