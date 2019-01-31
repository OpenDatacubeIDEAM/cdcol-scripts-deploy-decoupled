#!/bin/bash

if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi


#IPS
echo "¿Cuál es la ip del servidor de Bases de Datos?"
read ipdb

echo "¿Cuál es la ip del API REST?"
read ipapi

echo "¿Cuál es la ip del servidor NFS?"
read ipnfs

echo "¿Cuál es la ip pública de este servidor?"
read IP

#VARIABLES
PASSWORD_AIRFLOW='cubocubo'
USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
ANACONDA_URL="https://repo.anaconda.com/archive/Anaconda3-5.3.0-Linux-x86_64.sh"
OPEN_DATA_CUBE_REPOSITORY="https://github.com/opendatacube/datacube-core.git"
BRANCH="develop"



while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   echo "Waiting while other process ends installs (dpkg/lock is locked)"
   sleep 1
done

sudo apt install -y openssh-server postgresql-9.5 postgresql-client-9.5 postgresql-contrib-9.5 libgdal-dev libgdal1-dev libhdf5-serial-dev libnetcdf-dev hdf5-tools netcdf-bin gdal-bin pgadmin3 libhdf5-doc netcdf-doc libgdal-doc git wget htop imagemagick ffmpeg libpoppler-dev || exit 1
export CPLUS_INCLUDE_PATH=/usr/include/gdal
export C_INCLUDE_PATH=/usr/include/gdal
echo 'export CPLUS_INCLUDE_PATH="/usr/include/gdal"'>>$HOME/.bashrc
echo 'export C_INCLUDE_PATH="/usr/include/gdal"'>>$HOME/.bashrc

#CONDA INSTALL
if ! hash "conda" > /dev/null; then
	mkdir -p ~/instaladores && wget -c -P ~/instaladores $ANACONDA_URL
	bash ~/instaladores/Anaconda3-5.3.0-Linux-x86_64.sh -b -p $HOME/anaconda2
	export PATH="$HOME/anaconda2/bin:$PATH"
	echo 'export PATH="$HOME/anaconda2/bin:$PATH"'>>$HOME/.bashrc
fi

conda config --add channels conda-forge
conda install -c conda-forge libgdal gdal libiconv

git clone $OPEN_DATA_CUBE_REPOSITORY --branch $BRANCH
cd datacube-core
cat <<EOF >> requirements-test.txt
jupyter
matplotlib
scipy
hdf5
libnetcdf
shapely
ipywidgets
scipy
EOF
conda install -c conda-forge --force-reinstall --file requirements-test.txt
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

cd $HOME


conda install -y redis-py
conda install -c conda-forge flower celery=4.2
conda install -y -c conda-forge "airflow==1.10.1"
if [[ -z "${AIRFLOW_HOME}" ]]; then
    export AIRFLOW_HOME="$HOME/airflow"
    echo "export AIRFLOW_HOME='$HOME/airflow'" >>"$HOME/.bashrc"
fi


airflow initdb
sed -i "s%sql_alchemy_conn.*%sql_alchemy_conn = postgresql+psycopg2://airflow:$PASSWORD_AIRFLOW@$ipdb:5432/airflow%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%executor =.*%executor = CeleryExecutor%" "$AIRFLOW_HOME/airflow.cfg"

sed -i "s%broker_url =.*%broker_url = amqp://airflow:airflow@$ipapi/airflow%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%celery_result_backend =.*%celery_result_backend = redis://$ipdb:6379/0%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%endpoint_url = .*%endpoint_url = http://$IP:8080%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%base_url = .*%base_url = http://$IP:8080%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%flower_port = .*%flower_port = 8082%" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s%load_examples = .*%load_examples = False%" "$AIRFLOW_HOME/airflow.cfg"

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

mkdir  /web_storage/{dags,plugins}

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


airflow initdb

#AIRFLOW SERVICE


cd $HOME
source .bashrc
mkdir env
cat <<EOF >>/home/cubo/env/airflow
PATH="/home/cubo/anaconda2/bin:$PATH"
AIRFLOW_HOME='/home/cubo/airflow'
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
ExecStart= /home/cubo/anaconda2/bin/python /home/cubo/anaconda2/bin/airflow webserver
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
ExecStart=/home/cubo/anaconda2/bin/python /home/cubo/anaconda2/bin/airflow scheduler
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
ExecStart=/home/cubo/anaconda2/bin/python /home/cubo/anaconda2/bin/airflow flower
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

