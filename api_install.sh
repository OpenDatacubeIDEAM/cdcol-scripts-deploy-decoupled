#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi

echo "¿Cuál es la ip del servidor de Bases de Datos?"
read ipdb

echo "¿Cuál es la ip del servidor del web?"
read ipweb

echo "¿Cuál es la ip del servidor NFS?"
read ipnfs



sudo apt-get update

USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
ANACONDA_URL="https://repo.continuum.io/archive/Anaconda2-4.1.1-Linux-x86_64.sh"
REPO="git@gitlab.virtual.uniandes.edu.co:datacube-ideam/agdc-v2.git"
BRANCH="desacoplado"

sudo apt install -y openssh-server git wget htop rabbitmq-server nginx|| exit 1

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

git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/api-rest.git
cd api-rest
git checkout newDevelop
conda install -c conda-forge gunicorn djangorestframework psycopg2 PyYAML simplejson
pip install -r requirements.txt


sudo cat <<EOF >environment
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
