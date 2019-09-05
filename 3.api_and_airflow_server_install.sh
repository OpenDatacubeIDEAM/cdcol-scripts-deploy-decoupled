#!/bin/bash

if [[ $(id -u) -eq 0 ]] ; then 
	echo "This script must  not be excecuted \
	as root or using sudo(althougth the user must \
	be sudoer and password will be asked in some steps)" ; 
	exit 1 ; 
fi

echo "¿Cuál es la ip del servidor de Bases de Datos?"
read ipdb

echo "¿Cuál es la ip del API REST?"
read ipapi

echo "¿Cuál es la ip del servidor NFS?"
read ipnfs

# echo "¿Cuál es la ip pública de este servidor?"
# read IP
# Getting Host IP address and CIDR mask. Ex: 192.168.205.4/24
IP=$(ip -o -f inet addr show | awk '/scope global/ {print $4}')

# Split address and CIDR mask
IFS='/' read -r Address MaskCIDR <<< "$IP"
IP=$Address

sudo sed -i "\$a$ipnfs   nfs" /etc/hosts
sudo sed -i "\$a$ipdb    db" /etc/hosts
sudo sed -i "\$a$ipapi   api" /etc/hosts

sudo apt-get update

#VARIABLES
PASSWORD_AIRFLOW='cubocubo'
USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
ANACONDA_URL="https://repo.anaconda.com/archive/Anaconda3-5.3.0-Linux-x86_64.sh"

OPEN_DATA_CUBE_REPOSITORY="https://github.com/opendatacube/datacube-core.git"
BRANCH="datacube-1.6.1"

API_REST_REPOSITORY="git@gitlab.virtual.uniandes.edu.co:datacube-ideam/api-rest.git"
API_REST_BRANCH="master"

CLEANER_REPOSITORY="git@gitlab.virtual.uniandes.edu.co:datacube-ideam/cdcol-cleaner.git"
CLEANER_BRANCH="master"

UPDATER_REPOSITORY="git@gitlab.virtual.uniandes.edu.co:datacube-ideam/execution-monitor.git"
UPDATER_BRANCH="master"

WORKFLOWS_REPOSITORY="git@gitlab.virtual.uniandes.edu.co:datacube-ideam/workflows.git"
WORKFLOWS_BRANCH="master"

sudo apt install -y \
	rabbitmq-server \
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
	imagemagick  ffmpeg|| exit 1


#CONDA INSTALL
if ! hash "conda" > /dev/null; then
	mkdir -p ~/instaladores && wget -c -P ~/instaladores $ANACONDA_URL
	bash ~/instaladores/Anaconda3-5.3.0-Linux-x86_64.sh -b -p $HOME/anaconda
	export PATH="$HOME/anaconda/bin:$PATH"
	export SLUGIFY_USES_TEXT_UNIDECODE=yes
	echo 'export PATH="$HOME/anaconda/bin:$PATH"'>>$HOME/.bashrc
	echo 'export SLUGIFY_USES_TEXT_UNIDECODE=yes'>>$HOME/.bashrc
fi

source $HOME/.bashrc

# To avoid this error
# OSError: [Errno 13] Permiso denegado: 
# '/home/cubo/.cache/pip/wheels/ab/4f/e6/....
sudo chown -R cubo:cubo /home/cubo/.cache
sudo chown -R cubo:cubo /home/cubo/.conda

conda install -y python=3.6.8
/home/cubo/anaconda/bin/pip install conda

conda install -y jupyter matplotlib scipy
conda install -y gdal libgdal
conda install -y \
	psycopg2 hdf5 \
	rasterio netcdf4 \
	libnetcdf pandas \
	shapely ipywidgets \
	scipy numpy

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

cd $HOME

sudo rabbitmqctl add_user cdcol cdcol
sudo rabbitmqctl add_vhost cdcol
sudo rabbitmqctl set_user_tags cdcol cdcol_tag
sudo rabbitmqctl set_permissions -p cdcol cdcol ".*" ".*" ".*"
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmqctl set_user_tags cdcol cdcol_tag administrator
sudo rabbitmqctl add_user airflow airflow
sudo rabbitmqctl add_vhost airflow
sudo rabbitmqctl set_permissions -p airflow airflow ".*" ".*" ".*"
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmqctl set_user_tags airflow airflow_tag administrator
sudo service rabbitmq-server restart

cd $HOME

# ===================================== Airflow Install ====================================

# Airflow Install script
conda install -y -c conda-forge psycopg2 redis-py flower celery=4.2
/home/cubo/anaconda/bin/pip install conda
/home/cubo/anaconda/bin/pip install "apache-airflow==1.10.2"

# conda install -y redis-py flower celery=4.2
# conda install -y -c conda-forge "airflow==1.10.1"

if [[ -z "${AIRFLOW_HOME}" ]]; then
    export AIRFLOW_HOME="$HOME/airflow"
    echo "export AIRFLOW_HOME='$HOME/airflow'" >>"$HOME/.bashrc"
fi


# airflow initdb
sed -i "s%sql_alchemy_conn.*%sql_alchemy_conn = postgresql+psycopg2://airflow:$PASSWORD_AIRFLOW@db:5432/airflow%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%executor =.*%executor = CeleryExecutor%" "$AIRFLOW_HOME/airflow.cfg"

sed -i "s%broker_url =.*%broker_url = amqp://airflow:airflow@$api/airflow%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%result_backend =.*%result_backend = db+postgresql://airflow:$PASSWORD_AIRFLOW@db:5432/airflow%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%endpoint_url = .*%endpoint_url = http://$IP:8080%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%base_url = .*%base_url = http://$IP:8080%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%flower_port = .*%flower_port = 8082%" "$AIRFLOW_HOME/airflow.cfg"
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

mkdir  /web_storage/{dags,plugins,logs}

ln -s /web_storage/dags "$AIRFLOW_HOME/dags"
ln -s /web_storage/plugins "$AIRFLOW_HOME/plugins"
touch /home/cubo/airflow/dags/dummy.py
cat <<EOF >>/home/cubo/airflow/dags/dummy.py
import airflow
from airflow.models import DAG
from airflow.operators.dummy_operator import DummyOperator
from datetime import timedelta
args = {
    'owner': 'airflow',
    'start_date': airflow.utils.dates.days_ago(2)
}
dag = DAG(
    dag_id='example_dummy', default_args=args,
    schedule_interval=None,
    dagrun_timeout=timedelta(minutes=1))
run_this_last = DummyOperator(task_id='DOES_NOTHING', dag=dag)
EOF

# =========================== PLUGINS AND WORKFLOWS ==========================
mkdir -p ~/workflows

git clone $WORKFLOWS_REPOSITORY -b $WORKFLOWS_BRANCH ~/workflows

cp -r ~/workflows/dags/cdcol_utils "$AIRFLOW_HOME/dags"
cp -r ~/workflows/plugins/cdcol_plugin "$AIRFLOW_HOME/plugins"

mkdir -p /web_storage/algorithms
# mkdir -p /web_storage/media_root/algorithms
cp -r ~/workflows/algorithms/workflows /web_storage/algorithms/


airflow initdb

#AIRFLOW SERVICE


cd $HOME
source .bashrc
mkdir env
cat <<EOF >>/home/cubo/env/airflow
PATH="$HOME/anaconda/bin:$PATH"
AIRFLOW_HOME='/home/cubo/airflow'
SLUGIFY_USES_TEXT_UNIDECODE=yes
EOF

sudo touch /etc/systemd/system/airflow-webserver.service
sudo chmod o+w /etc/systemd/system/airflow-webserver.service
cat <<EOF >/etc/systemd/system/airflow-webserver.service
[Unit]
Description=Airflow webserver daemon
After=network.target


[Service]
EnvironmentFile=/home/cubo/env/airflow
User=cubo
Group=cubo
Type=simple
ExecStart= /home/cubo/anaconda/bin/python3 /home/cubo/anaconda/bin/airflow webserver
Restart=on-failure
RestartSec=5s
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
sudo chmod o-w /etc/systemd/system/airflow-webserver.service


sudo touch /etc/systemd/system/airflow-scheduler.service
sudo chmod o+w /etc/systemd/system/airflow-scheduler.service
cat <<EOF >/etc/systemd/system/airflow-scheduler.service
[Unit]
Description=Airflow scheduler daemon
After=network.target


[Service]
EnvironmentFile=/home/cubo/env/airflow
User=cubo
Group=cubo
Type=simple
ExecStart=/home/cubo/anaconda/bin/python3 /home/cubo/anaconda/bin/airflow scheduler
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
sudo chmod o-w /etc/systemd/system/airflow-scheduler.service

sudo touch /etc/systemd/system/flower.service
sudo chmod o+w /etc/systemd/system/flower.service
cat <<EOF >/etc/systemd/system/flower.service
[Unit]
Description=Airflow flower daemon
After=network.target


[Service]
EnvironmentFile=/home/cubo/env/airflow
User=cubo
Group=cubo
Type=simple
ExecStart=/home/cubo/anaconda/bin/python3 /home/cubo/anaconda/bin/airflow flower
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
sudo chmod o-w /etc/systemd/system/flower.service


sudo systemctl daemon-reload
sudo systemctl start airflow-webserver
sudo systemctl enable airflow-webserver

sudo systemctl start airflow-scheduler
sudo systemctl enable airflow-scheduler

sudo systemctl start flower
sudo systemctl enable flower

# ===================================== API Rest Install ====================================

cd $HOME

mkdir -p api-rest
git clone $API_REST_REPOSITORY --branch $API_REST_BRANCH api-rest
cd api-rest

source $HOME/.bashrc

conda install -c conda-forge gunicorn djangorestframework psycopg2 PyYAML simplejson
/home/cubo/anaconda/bin/pip install -r requirements.txt

sudo cat <<EOF >environment
# Connection for Web site database
WEB_DBHOST='db'
WEB_DBPORT='5432'
WEB_DBNAME='ideam'
WEB_DBUSER='portal_web'
WEB_DBPASSWORD='CDCol_web_2016'

# Connection for Datacube database
DATACUBE_DBHOST='db'
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

#GIF script
GEN_GIF_SCRIPT='/home/cubo/api-rest/scripts/generate_gif.sh'
 
#Results path
RESULTS='/web_storage/results'

#Airflow dag path
AIRFLOW_DAG_PATH='/web_storage/dags'

#Template Path
TEMPLATE_PATH='/web_storage/templates'

#Donwload Path
DOWNLOAD_PATH='/web_storage/downloads'

#Workflow Algorithms Path
WORKFLOW_ALGORITHMS_PATH='/web_storage/algorithms/workflows'
EOF

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
EnvironmentFile=/home/cubo/api-rest/environment
ExecStart=/home/cubo/anaconda/bin/gunicorn --timeout 36000 --bind 0.0.0.0:8000 --error-logfile /home/cubo/gunicorn-error.log cdcol.wsgi:application
 
[Install]
WantedBy=multi-user.target
EOF
sudo chmod o-w /etc/systemd/system/gunicorn.service

sudo systemctl stop gunicorn
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
