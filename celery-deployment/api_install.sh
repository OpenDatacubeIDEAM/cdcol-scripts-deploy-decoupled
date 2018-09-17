#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi

echo "¿Cuál es la ip del servidor de Bases de Datos?"
read ipdb

echo "¿Cuál es la ip del servidor del web?"
read ipweb

echo "¿Cuál es la ip del servidor NFS?"
read ipnfs

sudo apt-get update

git clone -b desacoplado git@gitlab.virtual.uniandes.edu.co:datacube-ideam/CDCol.git
mv CDCol/* ~/

USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
ANACONDA_URL="https://repo.continuum.io/archive/Anaconda2-4.1.1-Linux-x86_64.sh"
REPO="git@gitlab.virtual.uniandes.edu.co:datacube-ideam/agdc-v2.git"
BRANCH="desacoplado"

sudo apt install -y openssh-server postgresql-9.5 postgresql-client-9.5 postgresql-contrib-9.5 libgdal1-dev libhdf5-serial-dev libnetcdf-dev hdf5-tools netcdf-bin gdal-bin pgadmin3 postgresql-doc-9.5 libhdf5-doc netcdf-doc libgdal-doc git wget htop rabbitmq-server imagemagick ffmpeg nginx|| exit 1

if ! hash "conda" > /dev/null; then
	mkdir -p ~/instaladores && wget -c -P ~/instaladores $ANACONDA_URL
	bash ~/instaladores/Anaconda2-4.1.1-Linux-x86_64.sh -b -p $HOME/anaconda2
	export PATH="$HOME/anaconda2/bin:$PATH"
	echo 'export PATH="$HOME/anaconda2/bin:$PATH"'>>$HOME/.bashrc
fi

conda install -y psycopg2 gdal libgdal hdf5 rasterio netcdf4 libnetcdf pandas shapely ipywidgets scipy numpy


git clone $REPO
cd agdc-v2
git checkout $BRANCH
python setup.py install


cat <<EOF >~/.datacube.conf
[datacube]
db_database: datacube

# A blank host will use a local socket. Specify a hostname to use TCP.
db_hostname: $ipdb

# Credentials are optional: you might have other Postgres authentication configured.
# The default username otherwise is the current user id.
db_username: $USUARIO_CUBO
db_password: $PASSWORD_CUBO
EOF

datacube -v system init
source $HOME/.bashrc
sudo groupadd ingesters
sudo mkdir /dc_storage
sudo mkdir /source_storage
sudo chown $USUARIO_CUBO:ingesters /dc_storage
sudo chmod -R g+rwxs /dc_storage
sudo chown $USUARIO_CUBO:ingesters /source_storage
sudo chmod -R g+rwxs /source_storage
sudo mkdir /web_storage
sudo chown $USUARIO_CUBO /web_storage
#Crear un usuario ingestor
pass=$(perl -e 'print crypt($ARGV[0], "password")' "uniandes")
sudo useradd  --no-create-home -G ingesters -p $pass ingestor --shell="/usr/sbin/nologin" --home /source_storage  -K UMASK=002


sudo rabbitmqctl add_user cdcol cdcol
sudo rabbitmqctl add_vhost cdcol
sudo rabbitmqctl set_user_tags cdcol cdcol_tag
sudo rabbitmqctl set_permissions -p cdcol cdcol ".*" ".*" ".*"
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmqctl set_user_tags cdcol cdcol_tag administrator
sudo service rabbitmq-server restart

cd $HOME

git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/api-rest.git
cd api-rest
conda install -c conda-forge gunicorn djangorestframework psycopg2 PyYAML simplejson
pip install -r requirements.txt


sudo cat <<EOF >env_vars
# Connection for Web site database
WEB_DBHOST='$ipdb'
WEB_DBPORT='5432'
WEB_DBNAME='ideam'
WEB_DBUSER='portal_web'
WEB_DBPASSWORD='CDCol_web_2016'

# Connection for Datacube database
DATACUBE_DBHOST='$ipdb'
DATACUBE_DBPORT='5432'
DATACUBE_DBNAME='datacube'
DATACUBE_DBUSER='$(whoami)'
DATACUBE_DBPASSWORD='ASDFADFASSDFA'

# Datacube Storage folder
DC_STORAGE='/dc_storage'

# Ingestion folder
TO_INGEST='/source_storage'

# Web Storage folder
WEB_THUMBNAILS='/web_storage/thumbnails'

# Celery generic task script
GEN_TASK_MOD='cdcol_celery.tasks'
 
#Convert NetCDF to TIFF
TIFF_CONV_SCRIPT='/home/cubo/api-rest/scripts/download_geotiff.sh'
 
#GIF script
GEN_GIF_SCRIPT='/home/cubo/api-rest/scripts/generate_gif.sh'
 
#Results path
RESULTS='/web_storage/results'
EOF

ln -s ~/cdcol_celery
sudo touch /etc/systemd/system/gunicorn.service
sudo chmod o+w /etc/systemd/system/gunicorn.service
cat <<EOF >/etc/systemd/system/gunicorn.service
[Unit]
Description=gunicorn daemon
After=network.target
 
[Service]
User=cubo
Group=cubo
WorkingDirectory=/home/cubo/api-rest
EnvironmentFile=/home/cubo/api-rest/env_vars
ExecStart=/home/cubo/anaconda2/bin/gunicorn --timeout 36000 --bind 0.0.0.0:8000 --error-logfile /home/cubo/gunicorn-error.log cdcol.wsgi:application
 
[Install]
WantedBy=multi-user.target
EOF
sudo chmod o-w /etc/systemd/system/gunicorn.service

sudo systemctl stop gunicorn
/home/cubo/anaconda2/bin/gunicorn --bind 0.0.0.0:8000 --error-logfile /home/cubo/gunicorn-error.log cdcol.wsgi:application
sudo systemctl stop gunicorn
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn

#MOUNT NFS SERVER
cd $HOME

sudo apt install nfs-common
sudo chmod o+w /etc/fstab
sudo cat <<EOF >>/etc/fstab
#$ipnfs:/source_storage	/source_storage nfs 	defaults    	0   	0
$ipnfs:/dc_storage		/dc_storage 	nfs 	defaults    	0   	0
$ipnfs:/web_storage   	/web_storage	nfs 	defaults    	0   	0
EOF
sudo chmod o-w /etc/fstab

sudo mkdir /dc_storage /web_storage /source_storage
sudo chown cubo:root /dc_storage /web_storage /source_storage
sudo mount /dc_storage
#sudo mount /source_storage
sudo mount /web_storage



#CDCOL_CLEANER

cd $HOME
git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/cdcol-cleaner.git
cd cdcol-cleaner
sudo chmod 775 ~/cdcol-cleaner/run.sh
sudo cat <<EOF >settings.conf
[database]
host = $ipdb
port = 5432
name = ideam
user = portal_web
password = CDCol_web_2016
 
[paths]
results_path = /web_storage/results

[other]
lock_file = pid.lock
days = 360
EOF
(crontab -l 2>/dev/null; echo "0   0   *   *   *	/home/cubo/cdcol-cleaner/run.sh >> /home/cubo/cdcol-cleaner/out.log 2>> /home/cubo/cdcol-cleaner/err.log") | crontab -

