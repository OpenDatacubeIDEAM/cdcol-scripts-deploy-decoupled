#!/bin/bash
if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi

USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
ANACONDA_URL="https://repo.continuum.io/archive/Anaconda2-4.1.1-Linux-x86_64.sh"
REPO="https://github.com/cronosnull/agdc-v2.git"
BRANCH="develop"

sudo apt-get update
sudo apt-get install python-pip python-dev libpq-dev postgresql postgresql-contrib nginx virtualenv gunicorn git
pip install virtualenv
virtualenv v_ideam
source v_ideam/bin/activate
mkdir projects
cd projects
git clone -b develop https://MPMancipe@bitbucket.org/ideam20162/web-app.git
cd web-app
pip install -r requirements.txt

cat <<EOF >~/.bashrc
export IDEAM_DATABASE_URL="postgres://portal_web:CDCol_web_2016@IP_API_REST/ideam"
export IDEAM_PRODUCTION_DATABASE_URL="postgres://portal_web:CDCol_web_2016@IP_API_REST/ideam"
export IDEAM_API_URL="http://IP_API_REST:8000"
export IDEAM_MAIL_HOST="smtp.gmail.com"
export IDEAM_MAIL_USER="cdcolprueba@gmail.com"
export IDEAM_MAIL_PASSWORD="ideam20162"
export IDEAM_MAIL_PORT="587"
export IDEAM_DC_STORAGE_PATH="/dc_storage"
export IDEAM_WEB_STORAGE_PATH="/web_storage"
EOF

source ~/.bashrc
source ~/v_ideam/bin/activate
python manage.py migrate
python manage.py collectstatic
python manage.py createsuperuser