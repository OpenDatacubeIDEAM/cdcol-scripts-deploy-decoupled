#!/usr/bin/env bash

if [[ $(id -u) -eq 0 ]] ; then 
	echo "This script must  not be excecuted \
	as root or using sudo(althougth the user must \
	be sudoer and password will be asked in some steps)" ; 
	exit 1 ; 
fi

echo "¿Cuál es la ip del servidor de Bases de Datos?"
read ipdb

echo "¿Cuál es la ip del servidor NFS?"
read ipnfs

echo "¿Cuál es la ip del API REST?"
read ipapi

echo "¿Cuál es la ip del servidor AIRFLOW?"
read ipairflow


sudo sed -i "\$a$ipnfs   nfs" /etc/hosts
sudo sed -i "\$a$ipdb    db" /etc/hosts
sudo sed -i "\$a$ipapi   api" /etc/hosts
sudo sed -i "\$a$ipairflow   airflow_server" /etc/hosts


sudo apt-get update

#VARIABLES
PASSWORD_AIRFLOW='cubocubo'
USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
ANACONDA_URL="https://repo.anaconda.com/archive/Anaconda3-5.3.0-Linux-x86_64.sh"
OPEN_DATA_CUBE_REPOSITORY="https://github.com/opendatacube/datacube-core.git"
BRANCH="datacube-1.6.1"


while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   echo "Waiting while other process ends installs (dpkg/lock is locked)"
   sleep 1
done

sudo apt install -y \
	openssh-server \
	postgresql-9.5 \
	postgresql-client-9.5 \
	postgresql-contrib-9.5 \
	libgdal1-dev \
	libhdf5-serial-dev \
	libnetcdf-dev \
	hdf5-tools \
	netcdf-bin \
	gdal-bin \
	pgadmin3 \
	libhdf5-doc \
	netcdf-doc \
	libgdal-doc \
	git \
	wget \
	htop \
	imagemagick ffmpeg|| exit 1


#CONDA INSTALL
if ! hash "conda" > /dev/null; then
	mkdir -p ~/instaladores && wget -c -P ~/instaladores $ANACONDA_URL
	bash ~/instaladores/Anaconda3-5.3.0-Linux-x86_64.sh -b -p $HOME/anaconda
	export PATH="$HOME/anaconda/bin:$PATH"
	export SLUGIFY_USES_TEXT_UNIDECODE=yes
	echo 'export PATH="$HOME/anaconda/bin:$PATH"'>>$HOME/.bashrc
	echo 'export SLUGIFY_USES_TEXT_UNIDECODE=yes'>>$HOME/.bashrc
fi

# To avoid this error
# OSError: [Errno 13] Permiso denegado: 
# '/home/cubo/.cache/pip/wheels/ab/4f/e6/....
sudo chown -R cubo:cubo /home/cubo/.cache
sudo chown -R cubo:cubo /home/cubo/.conda

source $HOME/.bashrc
conda install -y python=3.6.8 conda=4.6.14
conda install -y \
	jupyter matplotlib scipy \
	gdal libgdal psycopg2 \
	hdf5 rasterio netcdf4 \
	libnetcdf pandas shapely \
	ipywidgets scipy numpy conda=4.6.14

# downgrade sqlalchemy required for datacube 1.6.1
pip install sqlalchemy==1.1.18 

cat <<EOF >~/.datacube.conf
[datacube]
db_database: datacube

# A blank host will use a local socket. Specify a hostname to use TCP.
db_hostname: db

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

# Airflow Install script
conda install -y -c conda-forge psycopg2 redis-py flower celery=4.2 conda=4.6.14
conda install -y -c anaconda scikit-learn conda=4.6.14
/home/cubo/anaconda/bin/pip install "apache-airflow==1.10.2"
# conda install -y -c conda-forge psycopg2 redis-py flower celery=4.2
# conda install -y -c conda-forge "airflow==1.10.1"

if [[ -z "${AIRFLOW_HOME}" ]]; then
    export AIRFLOW_HOME="$HOME/airflow"
    echo "export AIRFLOW_HOME='$HOME/airflow'" >>"$HOME/.bashrc"
fi

airflow initdb
sed -i "s%sql_alchemy_conn.*%sql_alchemy_conn = postgresql+psycopg2://airflow:$PASSWORD_AIRFLOW@db:5432/airflow%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%executor =.*%executor = CeleryExecutor%" "$AIRFLOW_HOME/airflow.cfg"

sed -i "s%broker_url =.*%broker_url = amqp://airflow:airflow@api/airflow%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%result_backend =.*%result_backend = db+postgresql://airflow:$PASSWORD_AIRFLOW@db:5432/airflow%" "$AIRFLOW_HOME/airflow.cfg"

sed -i "s%endpoint_url = .*%endpoint_url = http://airflow_server:8080%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%base_url = .*%base_url = http://airflow_server:8080%" "$AIRFLOW_HOME/airflow.cfg"

sed -i "s%load_examples = .*%load_examples = False%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%base_log_folder = .*%base_log_folder = /web_storage/logs%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%dags_are_paused_at_creation = .*%dags_are_paused_at_creation = False%" "$AIRFLOW_HOME/airflow.cfg"

#MOUNT NFS SERVER
cd $HOME

sudo apt install -y nfs-common
sudo chmod o+w /etc/fstab
cat <<EOF >>/etc/fstab
nfs:/source_storage	/source_storage nfs 	defaults    	0   	0
nfs:/dc_storage		/dc_storage 	nfs 	defaults    	0   	0
nfs:/web_storage   	/web_storage	nfs 	defaults    	0   	0
EOF
sudo chmod o-w /etc/fstab

sudo mkdir /dc_storage /web_storage /source_storage

sudo chown cubo:root /dc_storage /web_storage /source_storage
sudo mount /dc_storage
sudo mount /source_storage
sudo mount /web_storage

ln -s /web_storage/dags "$AIRFLOW_HOME/dags"
ln -s /web_storage/plugins "$AIRFLOW_HOME/plugins"


#AIRFLOW SERVICE
cd $HOME
source .bashrc
mkdir env
cat <<EOF >>/home/cubo/env/airflow
PATH="$HOME/anaconda/bin:$PATH"
AIRFLOW_HOME='/home/cubo/airflow'
SLUGIFY_USES_TEXT_UNIDECODE=yes
EOF

sudo touch /etc/systemd/system/airflow-worker.service
sudo chmod o+w /etc/systemd/system/airflow-worker.service
cat <<EOF >/etc/systemd/system/airflow-worker.service
[Unit]
Description=Airflow celery worker daemon
After=network.target


[Service]
EnvironmentFile=/home/cubo/env/airflow
User=cubo
Group=cubo
Type=simple
ExecStart=/home/cubo/anaconda/bin/python3 /home/cubo/anaconda/bin/airflow worker --concurrency 1 --queues util,airflow_small,airflow_medium,airflow_large,airflow_xlarge


[Install]
WantedBy=multi-user.target
EOF
sudo chmod o-w /etc/systemd/system/airflow-worker.service
sudo systemctl daemon-reload
sudo systemctl start airflow-worker
sudo systemctl enable airflow-worker
