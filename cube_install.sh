if [[ $(id -u) -eq 0 ]] ; then echo "This script must  not be excecuted as root or using sudo(althougth the user must be sudoer and password will be asked in some steps)" ; exit 1 ; fi

sudo apt-get update


USUARIO_CUBO="$(whoami)"
PASSWORD_CUBO='ASDFADFASSDFA'
ANACONDA_URL="https://repo.continuum.io/archive/Anaconda2-4.1.1-Linux-x86_64.sh"
REPO="https://github.com/cronosnull/agdc-v2.git"
BRANCH="develop"

git clone http://usuario@gitlab.virtual.uniandes.edu.co/datacube-ideam/CDCol.git
mv CDCol/* ~/

#Prerequisites installation: 
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

git clone $REPO
cd agdc-v2
git checkout $BRANCH
python setup.py install

echo "¿Cuál es la ip del servidor de Bases de Datos?"
read ipdb

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

conda install -c conda-forge celery=3.1.23
ip=`hostname -I | awk '{ print $1 }'`
echo "iniciando celery en la ip $ip en el puerto 8082"
nohup celery -A cdcol_celery worker --loglevel=info &
nohup celery -A cdcol_celery flower --port=8082 --address=$ip --persistent &



#MOUNT NFS SERVER
cd $HOME
echo "¿Cuál es la ip del servidor NFS?"
read ipnfs
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