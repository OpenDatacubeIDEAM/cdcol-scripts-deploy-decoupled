#!/usr/bin/env bash


#VARIABLES
PASSWORD_AIRFLOW='cubocubo'
USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'

sudo apt update
sudo apt install \
  git \
  postgresql \
  postgresql-contrib \
  nginx \
  wget \
  xz-utils \
  build-essential \
  zlib1g-dev \
  libssl-dev

CONDA INSTALL
if ! hash "conda" > /dev/null; then
	mkdir -p ~/instaladores && wget -c -P ~/instaladores $ANACONDA_URL
	bash ~/instaladores/Anaconda3-5.3.0-Linux-x86_64.sh -b -p $HOME/anaconda
	export PATH="$HOME/anaconda/bin:$PATH"
	export SLUGIFY_USES_TEXT_UNIDECODE=yes
	echo 'export PATH="$HOME/anaconda/bin:$PATH"'>>$HOME/.bashrc
	echo 'export SLUGIFY_USES_TEXT_UNIDECODE=yes'>>$HOME/.bashrc
fi

source $HOME/.bashrc
conda install -y python=3.6.8


# To avoid this error
# OSError: [Errno 13] Permiso denegado:
# '/home/cubo/.cache/pip/wheels/ab/4f/e6/....
sudo chown -R cubo:cubo /home/cubo/.cache
sudo chown -R cubo:cubo /usr/local/lib/python
sudo chown -R cubo:cubo /usr/local/bin



# Install web application
source $HOME/.bashrc
cd ~
pip install virtualenv
virtualenv --python=python v_ideam
source ~/v_ideam/bin/activate

git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/web-app.git -b newDevelop ~/projects/web-app
cd ~/projects/web-app

pip install -r requirements.txt

# Load web app env variables
export $(egrep -v '^#' environment | xargs)

python manage.py makemigrations
python manage.py migrate
python manage.py migrate --run-syncdb
python manage.py collectstatic

# Loading application initial data
python manage.py loaddata data/1.group.json
python manage.py loaddata data/2.user.json
python manage.py loaddata data/3.profile.json
python manage.py loaddata data/4.topic.json

deactivate

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
EnvironmentFile=/home/cubo/projects/web-app/environment
ExecStart=/home/cubo/v_ideam/bin/gunicorn --timeout 36000 --bind 0.0.0.0:8080 ideam.wsgi:application
 
[Install]
WantedBy=multi-user.target
EOF

sudo chmod o-w /etc/systemd/system/gunicorn.service

sudo systemctl enable gunicorn
sudo systemctl daemon-reload
sudo systemctl start gunicorn

# Configuring Nginx
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

    # Django allouth use this setting to set all 
    # host urls for account activation and verification
    proxy_set_header Host cdcol.ideam.gov.co;

    proxy_pass http://127.0.0.1:8080;
  }
}
EOF

sudo chmod o-w /etc/nginx/sites-available/ideam

sudo ln -s /etc/nginx/sites-available/ideam /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx


# Mount NFS Server
cd $HOME
sudo apt install nfs-common
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
cd $HOME


