if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi
#Prerequisites installation: 

echo "¿Cuál es la ip del servidor de Bases de Datos?"
read ipdb

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

while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   echo "Waiting while other process ends installs (dpkg/lock is locked)"
   sleep 1
done
sudo apt install -y openssh-server postgresql-9.5 postgresql-client-9.5 postgresql-contrib-9.5 libgdal1-dev libhdf5-serial-dev libnetcdf-dev hdf5-tools netcdf-bin gdal-bin pgadmin3 libhdf5-doc netcdf-doc libgdal-doc git wget htop imagemagick ffmpeg|| exit 1


if ! hash "conda" > /dev/null; then
	mkdir -p ~/instaladores && wget -c -P ~/instaladores $ANACONDA_URL
	bash ~/instaladores/Anaconda2-4.1.1-Linux-x86_64.sh -b -p $HOME/anaconda2
	export PATH="$HOME/anaconda2/bin:$PATH"
	echo 'export PATH="$HOME/anaconda2/bin:$PATH"'>>$HOME/.bashrc
fi

conda install -y psycopg2 gdal libgdal hdf5 rasterio netcdf4 libnetcdf pandas shapely ipywidgets scipy numpy
pip install --upgrade pip
pip install rasterio==1.0a9 --force-reinstall

git clone $REPO
cd agdc-v2
git checkout $BRANCH
python setup.py install



cat <<EOF >>~/.datacube.conf
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

#TODO: At this point an empty datacube is installed. Next steps are create datasets types, index datasets and ingest.  
#datacube product add ~/agdc-v2/docs/config_samples/dataset_types/ls7_scenes.yaml
datacube product add ~/agdc-v2/docs/config_samples/dataset_types/ls5_scenes.yaml
datacube product add ~/agdc-v2/docs/config_samples/dataset_types/ls8_scenes.yaml
datacube product add ~/agdc-v2/docs/config_samples/dataset_types/modis_tiles.yaml

#MOUNT NFS SERVER
cd $HOME
sudo apt install nfs-common

sudo chmod o+w /etc/fstab
cat <<EOF >>/etc/fstab
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

#Configuracion del CRON de ingesta
conda install -c conda-forge psycopg2 PyYAML
git clone -b desacoplado git@gitlab.virtual.uniandes.edu.co:datacube-ideam/ingestion-scheduler.git
cd ingestion-scheduler
cat <<EOF >settings.conf
[database]
host = $ipdb
port = 5432 
name = ideam
user = portal_web
password = CDCol_web_2016

[paths]
to_ingest = /source_storage
web_thumbnails = /web_storage/thumbnails

[other]
lock_file = /home/cubo/ingestion-scheduler/pid.lock 
ing_script = /home/cubo/ingestion-scheduler/scripts/ingestion.sh 
thumb_script = /home/cubo/ingestion-scheduler/scripts/generate_thumbnails.sh
thumb_x_res = 500 
thumb_y_res = 500
thumb_colors = /home/cubo/util/colores/cb_greys.png
EOF
sudo chmod 764 ~/ingestion-scheduler/scripts/generate_thumbnails.sh
(crontab -l 2>/dev/null; echo "0   0   *   *   *	/home/cubo/ingestion-scheduler/run.sh >> /home/cubo/ingestion-scheduler/out.log 2>> /home/cubo/ingestion-scheduler/err.log") | crontab -
