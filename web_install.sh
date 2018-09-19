#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi

echo "¿Cuál es la ip del servidor de Bases de Datos?"
read ipdb

echo "¿Cuál es la ip del API REST?"
read ipapi

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




if ! hash "conda" > /dev/null; then
	mkdir -p ~/instaladores && wget -c -P ~/instaladores $ANACONDA_URL
	bash ~/instaladores/Anaconda2-4.1.1-Linux-x86_64.sh -b -p $HOME/anaconda2
	export PATH="$HOME/anaconda2/bin:$PATH"
	echo 'export PATH="$HOME/anaconda2/bin:$PATH"'>>$HOME/.bashrc
fi
#Configurar Flower

conda install -c conda-forge flower celery=3.1.23
sudo touch /etc/systemd/system/flower.service
sudo chmod o+w /etc/systemd/system/flower.service
cat <<EOF >/etc/systemd/system/flower.service
[Unit]
Description=flower daemon

[Service]
User=cubo
Group=cubo
WorkingDirectory=/home/cubo/cdcol_celery
ExecStart=/home/cubo/anaconda2/bin/flower --broker=amqp://cdcol:cdcol@$ipapi/cdcol --port=8082 --loglevel=info
Restart=on-failure
Type=simple

[Install]
WantedBy=multi-user.target
EOF
sudo chmod o-w /etc/systemd/system/flower.service
echo "Iniciando flower en el puerto 8082"
sudo systemctl daemon-reload
sudo systemctl start flower
sudo systemctl enable flower


sudo apt-get update
sudo apt-get install python-pip python-dev libpq-dev postgresql postgresql-contrib nginx virtualenv gunicorn git
pip install virtualenv
virtualenv v_ideam
source v_ideam/bin/activate
mkdir projects
cd projects
git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/web-app.git
cd web-app
pip install -r requirements.txt

export IDEAM_DATABASE_URL="postgres://portal_web:CDCol_web_2016@$ipdb/ideam"
export IDEAM_PRODUCTION_DATABASE_URL="postgres://portal_web:CDCol_web_2016@$ipdb/ideam"
export IDEAM_API_URL="http://$ipapi:8000"
export IDEAM_MAIL_HOST="smtp.gmail.com"
export IDEAM_MAIL_USER="cdcolprueba@gmail.com"
export IDEAM_MAIL_PASSWORD="ideam20162"
export IDEAM_MAIL_PORT="587"
export IDEAM_DC_STORAGE_PATH="/dc_storage"
export IDEAM_WEB_STORAGE_PATH="/web_storage"

echo IDEAM_DATABASE_URL
echo $IDEAM_DATABASE_URL

python manage.py migrate
python manage.py collectstatic
python manage.py createsuperuser

sudo touch /etc/systemd/system/gunicorn.service
sudo chmod o+w /etc/systemd/system/gunicorn.service
cat <<EOF >/etc/systemd/system/gunicorn.service
[Unit]
Description=gunicorn daemon
After=network.target
 
[Service]
User=cubo
Group=cubo
WorkingDirectory=/home/cubo/projects/web-app
EnvironmentFile=/home/cubo/projects/web-app/.ideam.env
ExecStart=/home/cubo/v_ideam/bin/gunicorn --timeout 36000 --bind 0.0.0.0:8080 ideam_cdc.wsgi:application
 
[Install]
WantedBy=multi-user.target
EOF
sudo chmod o-w /etc/systemd/system/gunicorn.service

cat <<EOF >>.ideam.env
IDEAM_PRODUCTION_DATABASE_URL="postgres://portal_web:CDCol_web_2016@$ipdb/ideam"
IDEAM_DATABASE_URL="postgres://portal_web:CDCol_web_2016@$ipdb/ideam"
IDEAM_API_URL="http://$ipapi:8000"
IDEAM_MAIL_HOST="smtp.gmail.com"
IDEAM_MAIL_USER="cdcolprueba@gmail.com"
IDEAM_MAIL_PASSWORD="ideam20162"
IDEAM_MAIL_PORT="587"
IDEAM_DC_STORAGE_PATH="/dc_storage"
IDEAM_WEB_STORAGE_PATH="/web_storage"
IDEAM_TEMPORIZER="3000"
IDEAM_DAYS_ELAPSED_TO_DELETE_EXECUTION_RESULTS="360"
IDEAM_ID_ALGORITHM_FOR_CUSTOM_SERVICE="8"
EOF

sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl daemon-reload
sudo systemctl status gunicorn
sudo systemctl stop gunicorn
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl status gunicorn

#Configuracion de Nginx
sudo touch /etc/nginx/sites-available/ideam
sudo chmod o+w /etc/nginx/sites-available/ideam
cat <<EOF >>/etc/nginx/sites-available/ideam
server {
  listen 80;

 location ~ ^/execution/download/image/(?<exec>[0-9]+)/(?<archivo>.*)$ {
        alias /web_storage/results/$exec/$archivo;
  }

  location ~ ^/execution/download/zip/(?<exec>[0-9]+)/(?<param>.+)/(?<archivo>.*)$ {
        alias /web_storage/media_root/input/$exec/$param/$archivo;
  }

  location ~ ^/storage/download/file/(?<storage>.*)/(?<file>.+)$ {
        alias /dc_storage/$storage/$file;
  }

  location ~ ^/storage/download/image/(?<storage>.*)/(?<file>.+)$ {
        alias /dc_storage/$storage/$file;
  }

  location ~ ^/algorithm/version/download/sourcecode/(?<source>.*)$ {
        alias /web_storage/media_root/algorithms/$source;
  }

  location /web_storage {
    alias /web_storage;
  }


  location / {
    proxy_read_timeout 36000;
    client_max_body_size 500M;
    proxy_set_header Host $http_host;
    proxy_pass http://127.0.0.1:8080;
  }
}
EOF
sudo chmod o-w /etc/nginx/sites-available/ideam

sudo ln -s /etc/nginx/sites-available/ideam /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
deactivate



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
cd $HOME

#Configuracion CRON envio de correos
cd projects/web-app/
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/cubo/projects/web-app/run.sh >> /home/cubo/projects/email_notifier.log 2>> /home/cubo/projects/email_notifier_error.log") | crontab -


