#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi

sudo apt-get update

USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
ANACONDA_URL="https://repo.continuum.io/archive/Anaconda2-4.1.1-Linux-x86_64.sh"
REPO="https://github.com/cronosnull/agdc-v2.git"
BRANCH="develop"

sudo apt install -y openssh-server postgresql-client-9.5 postgresql-contrib-9.5 pgadmin3 git wget htop imagemagick ffmpeg nginx|| exit 1

if ! hash "conda" > /dev/null; then
	mkdir -p ~/instaladores && wget -c -P ~/instaladores $ANACONDA_URL
	bash ~/instaladores/Anaconda2-4.1.1-Linux-x86_64.sh -b -p $HOME/anaconda2
	export PATH="$HOME/anaconda2/bin:$PATH"
	echo 'export PATH="$HOME/anaconda2/bin:$PATH"'>>$HOME/.bashrc
fi

conda install -y psycopg2 gdal libgdal hdf5 rasterio netcdf4 libnetcdf pandas shapely ipywidgets scipy numpy
git clone https://MPMancipe@bitbucket.org/ideam20162/api-rest.git
cd api-rest
conda install -c conda-forge gunicorn djangorestframework psycopg2 PyYAML simplejson
pip install -r requirements.txt

cat <<EOF >env_vars
# Connection for Web site database
WEB_DBHOST='127.0.0.1'
WEB_DBPORT='5432'
WEB_DBNAME='ideam'
WEB_DBUSER='portal_web'
WEB_DBPASSWORD='CDCol_web_2016'

# Connection for Datacube database
DATACUBE_DBHOST='127.0.0.1'
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

sudo systemctl stop gunicorn
/home/cubo/anaconda2/bin/gunicorn --bind 0.0.0.0:8000 --error-logfile /home/cubo/gunicorn-error.log cdcol.wsgi:application
sudo systemctl stop gunicorn
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn

#MOUNT NFS SERVER
cd $HOME
sudo apt install nfs-common
cat <<EOF >
IP_NFS_SERVER:/source_storage	/source_storage nfs 	defaults    	0   	0
IP_NFS_SERVER:/dc_storage		/dc_storage 	nfs 	defaults    	0   	0
IP_NFS_SERVER:/web_storage   	/web_storage	nfs 	defaults    	0   	0
EOF

sudo mkdir /dc_storage /web_storage /source_storage
sudo chown cubo:root /dc_storage /web_storage /source_storage
sudo mount /dc_storage
sudo mount /source_storage
sudo mount /web_storage

#EXECUTION MONITOR
cd $HOME
git clone https://MPMancipe@bitbucket.org/ideam20162/execution-monitor.git
cd execution-monitor
CAT <<EOF >
[database]
host = 127.0.0.1
port = 5432
name = ideam
user = portal_web
password = CDCol_web_2016


#La sección roja modificarla por la ip pública de la api
[flower]
url = http://157.253.198.190:8082

[other]
lock_file = pid.lock
results_path = /web_storage/results
make_mosaic_script = /home/cubo/execution-monitor/scripts/make_mosaic.sh
make_gif_script = /home/cubo/execution-monitor/scripts/generate_gif.sh
gif_algorithm_id = 0
EOF

(crontab -l 2>/dev/null; echo "*   *   *   *   *	/home/cubo/execution-monitor/run.sh >> /home/cubo/execution-monitor/out.log 2>> /home/cubo/execution-monitor/err.log") | crontab -


