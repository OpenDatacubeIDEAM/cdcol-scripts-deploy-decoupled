if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi
#Prerequisites installation: 

echo "¿Cuál es la ip del servidor de Bases de Datos?"
read ipdb

echo "¿Cuál es la ip del servidor web?"
read ipweb

echo "¿Cuál es la ip del servidor NFS?"
read ipnfs

sudo apt-get update

USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
ANACONDA_URL="https://repo.anaconda.com/archive/Anaconda3-5.3.0-Linux-x86_64.sh"
OPEN_DATA_CUBE_REPOSITORY="https://github.com/opendatacube/datacube-core.git"
BRANCH="datacube-1.6.2"

while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   echo "Waiting while other process ends installs (dpkg/lock is locked)"
   sleep 1
done

git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/CDCol.git --branch desacoplado
mv CDCol/* ~/

sudo apt install -y openssh-server postgresql-9.5 postgresql-client-9.5 postgresql-contrib-9.5 libgdal1-dev libhdf5-serial-dev libnetcdf-dev hdf5-tools netcdf-bin gdal-bin pgadmin3 libhdf5-doc netcdf-doc libgdal-doc git wget htop imagemagick ffmpeg|| exit 1


#CONDA INSTALL
if ! hash "conda" > /dev/null; then
	mkdir -p ~/instaladores && wget -c -P ~/instaladores $ANACONDA_URL
	bash ~/instaladores/Anaconda3-5.3.0-Linux-x86_64.sh -b -p $HOME/anaconda
	export PATH="$HOME/anaconda/bin:$PATH"
	echo 'export PATH="$HOME/anaconda/bin:$PATH"'>>$HOME/.bashrc
fi

source $HOME/.bashrc
conda install -y python=3.6.8
conda install -y jupyter matplotlib scipy
conda install -y psycopg2 gdal libgdal hdf5 rasterio netcdf4 libnetcdf pandas shapely ipywidgets scipy numpy



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

git clone $OPEN_DATA_CUBE_REPOSITORY --branch $BRANCH
cd datacube-core
python setup.py install

datacube -v system init
datacube system check

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


#MOUNT NFS SERVER
cd $HOME
sudo apt install nfs-common

sudo chmod o+w /etc/fstab
cat <<EOF >>/etc/fstab
$ipnfs:/source_storage	/source_storage nfs 	defaults    	0   	0
$ipnfs:/dc_storage		/dc_storage 	nfs 	defaults    	0   	0
$ipnfs:/web_storage   	/web_storage	nfs 	defaults    	0   	0
EOF
sudo chmod o-w /etc/fstab

sudo mkdir /dc_storage /web_storage /source_storage
sudo chown cubo:root /dc_storage /web_storage /source_storage
sudo mount /dc_storage
sudo mount /source_storage
sudo mount /web_storage

#Configuracion del CRON de ingesta
conda install -c conda-forge psycopg2 PyYAML
git clone  git@gitlab.virtual.uniandes.edu.co:datacube-ideam/ingestion-scheduler.git --branch open_data_cube
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


