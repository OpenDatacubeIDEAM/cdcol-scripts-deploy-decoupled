#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi

echo "¿Cuál es la ip del servidor de Bases de Datos?"
read ipdb

conda clean --all
conda remove --all --force-remove
conda install anaconda-clean
anaconda-clean --yes

cd $HOME
rm -rf *

export PATH=${PATH/':/home/cubo/anaconda2/bin'/}
sed -i '$ d' ~/.bashrc

sudo apt-get update

USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
ANACONDA_URL="https://repo.anaconda.com/archive/Anaconda3-5.3.0-Linux-x86_64.sh"
OPEN_DATA_CUBE_REPOSITORY="https://github.com/opendatacube/datacube-core.git"
BRANCH="1.6.2"

while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   echo "Waiting while other process ends installs (dpkg/lock is locked)"
   sleep 1
done

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

cd $HOME
#Configuracion del CRON de ingesta
conda install -c conda-forge PyYAML
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