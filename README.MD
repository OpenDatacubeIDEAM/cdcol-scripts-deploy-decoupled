# Data Cube Instalation Scripts

The repository contains instalation scripts for: NFS, DB, WEB, API, Airflow Server, Airflow Workers.

## Install NFS

Create the **cubo** user sing the following command:

```sh 
sudo adduser cubo
sudo usermod -aG sudo cubo
su cubo
cd
```

Install git

```sh 
sudo apt install git
```

Create a RSA key, change "aa.vivas@uniandes.edu.co" with your email, and add the content of the publick key .pub to your ssh keys in Github/Gitlab.

```sh 
ssh-keygen -t rsa -C aa.vivas@uniandes.edu.co -b 4096
```

Clone the repository and install the NFS server.

```sh 
git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/scripts-despliegue-desacoplado.git
cp scripts-despliegue-desacoplado/1.nfs_install.sh .
bash 1.nfs_install.sh
```

## Install DB

This script will

1. Install Postgres Database Manager System
2. Set the 'datacube' database
3. Set the 'airflow' database
4. Install redis

Create the **cubo** user sing the following command:

```sh 
sudo adduser cubo
sudo usermod -aG sudo cubo
su cubo
cd
```

Install git

```sh 
sudo apt install git
```

Copy the ssh key from the NFS server, change **172.24.99.217** for the IP of your NFS server.

```sh
mkdir ~/.ssh
scp cubo@172.24.99.217:/home/cubo/.ssh/id_rsa* .ssh/
sudo chown -R cubo:cubo .ssh
```

Run the script as follows:

```sh
git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/scripts-despliegue-desacoplado.git
cp scripts-despliegue-desacoplado/2.db_install.sh .
bash 2.db_install.sh
```

## Install Rest API and Airflow Server

This script will install:

1. RabbitMQ 
2. Airflow Server
3. [API Rest](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/api-rest)

Create the **cubo** user sing the following command:

```sh 
sudo adduser cubo
sudo usermod -aG sudo cubo
su cubo
cd
```

Install git

```sh 
sudo apt install git
```

Copy the ssh key from the NFS server, change **172.24.99.217** for the IP of your NFS server.

```sh
mkdir ~/.ssh
scp cubo@172.24.99.217:/home/cubo/.ssh/id_rsa* .ssh/
sudo chown -R cubo:cubo .ssh
```

Run the script as follows, replace

```sh
git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/scripts-despliegue-desacoplado.git
cp scripts-despliegue-desacoplado/3.api_and_airflow_server_install.sh .
bash 3.api_and_airflow_server_install.sh
```

## Install Airflow Worker

Create the **cubo** user sing the following command:

```sh 
sudo adduser cubo
sudo usermod -aG sudo cubo
su cubo
cd
```

Install git

```sh 
sudo apt install git
```

Copy the ssh key from the NFS server, change **172.24.99.217** for the IP of your NFS server.

```sh
mkdir ~/.ssh
scp cubo@172.24.99.217:/home/cubo/.ssh/id_rsa* .ssh/
sudo chown -R cubo:cubo .ssh
```

Run the script as follows, replace

```sh
git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/scripts-despliegue-desacoplado.git
cp scripts-despliegue-desacoplado/4.worker_airflow_install.sh .
bash 4.worker_airflow_install.sh
```

## Install Ingestor

This script will install

1. [CDCol](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/CDCol).
2. [Open Data Cube core](https://github.com/opendatacube/datacube-core.git). 
3. [Ingestor](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/ingestion-scheduler) cronjob. 

Create the **cubo** user sing the following command:

```sh 
sudo adduser cubo
sudo usermod -aG sudo cubo
su cubo
cd
```

Install git

```sh 
sudo apt install git
```

Copy the ssh key from the NFS server, change **172.24.99.217** for the IP of your NFS server.

```sh
mkdir ~/.ssh
scp cubo@172.24.99.217:/home/cubo/.ssh/id_rsa* .ssh/
sudo chown -R cubo:cubo .ssh
```

Run the script as follows

```sh 
git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/scripts-despliegue-desacoplado.git
cp scripts-despliegue-desacoplado/5.ingestion_install.sh .
bash 5.worker_airflow_install.sh
```

## Install Web

Create the **cubo** user sing the following command:

```sh 
sudo adduser cubo
sudo usermod -aG sudo cubo
su cubo
cd
```

Install git

```sh 
sudo apt install git
```

Copy the ssh key from the NFS server, change **172.24.99.217** for the IP of your NFS server.

```sh
mkdir ~/.ssh
scp cubo@172.24.99.217:/home/cubo/.ssh/id_rsa* .ssh/
sudo chown -R cubo:cubo .ssh
```

Run the script as follows

```sh 
git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/scripts-despliegue-desacoplado.git
cp scripts-despliegue-desacoplado/6.web_install.sh .
bash 6.web_install.sh
```

### Load Initial Data

Activate the Python environment used by the web-app

```sh 
source ~/v_ideam/bin/activate
cd ~/projects/web-app/
```

Load the environment variables needed for the web-app django project.

```sh 
# Load web app env variables
export $(egrep -v '^#' environment | xargs)
```

Load initial database data

```sh 
# Loading application initial data
python3.6 manage.py loaddata data/1.group.json
python3.6 manage.py loaddata data/2.user.json
python3.6 manage.py loaddata data/3.profile.json
python3.6 manage.py loaddata data/4.topic.json
```


### Install Workflows 

The workflows place the supporting utilities developed to support workflow processing in the corresponding place in the */web_storage* folder.

* dags/cdcol_utils: Utilities used in dag development.
* plugins/cdcol_plugin: Ariflow Operators and Sensors.
* algorithm/workflows: Repository of mini-algorithms that can be pluged into workflows.

Run the script as follows

```sh 
git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/scripts-despliegue-desacoplado.git
cp scripts-despliegue-desacoplado/7.workflows_install.sh .
bash 7.workflows_install.sh
```

## Known Issues

With Anaconda 

* [Installing from conda-forge breaks conda's installation](https://github.com/conda-forge/conda-forge.github.io/issues/547)

* [conda v4.5.0](https://github.com/conda-forge/conda-feedstock/pull/42)
* [Everything is broken: upgrade conda to version 4.4+ #43](https://github.com/conda-forge/conda-feedstock/issues/43#comment-375152359)

Posible solutions

* [resetting conda channel priorities](https://stackoverflow.com/questions/48547046/resetting-conda-channel-priorities)
* [should_bypass_proxies still an issue in 4.5.7 #7524](https://github.com/conda/conda/issues/7524)