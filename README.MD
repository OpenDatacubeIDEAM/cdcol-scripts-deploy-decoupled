# Data Cube Instalation Scripts

## Create the cubo User

Create the cube user in every machine:

* NFS
* DB
* WEB
* API
* Airflow Server
* Airflow Workers

Using the following command:

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

## Install NFS

Create a RSA key, change "aa.vivas@uniandes.edu.co" with your email, and add the content of the publick key .pub to your ssh keys in Github/Gitlab.

```sh 
ssh-keygen -t rsa -C aa.vivas@uniandes.edu.co -b 4096
```

Clone the repository and install the NFS server. This will create */dc_storage*, */web_storage* and */source_storage* shared directories.

```sh 
git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/scripts-despliegue-desacoplado.git
cd scripts-despliegue-desacoplado/
bash 1.nfs_install.sh
```

## Install DB

This script will

1. Install Postgres Database Manager System
2. Set the 'datacube' database
3. Set the 'airflow' database
4. Install redis

Copy the ssh key from the NFS server, change **172.24.99.217** for the IP of your NFS server.

```sh
mkdir ~/.ssh
scp cubo@172.24.99.217:/home/cubo/.ssh/id_rsa* .ssh/
sudo chown -R cubo:cubo .ssh
```

Run the script as follows:

```sh
git clone git@gitlab.virtual.uniandes.edu.co:datacube-ideam/scripts-despliegue-desacoplado.git
cd scripts-despliegue-desacoplado/
bash 2.db_install.sh
```

## Install Rest API

This script will install:

1. [CDCol](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/CDCol): modules that use the open datacube API for Colombian's needs.
2. [OpenDataCube](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/agdc-v2) (ODC) API from Australian Geoscience Data Cube v2.
3. RabbitMQ: It is an open source multi-protocol messaging broker.
4. [API Rest](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/api-rest): It exposes some features of the ODC through internet.

Run the script as follows, replace

```sh 
bash api_install.sh 
```

If you need to keep instalation logs use **tee** to save **stdout** and **stderr**.

```sh
bash api_install.sh db_ip nfs_ip 2>&1 | tee logs.txt
```

## Install Ingestor

This script will install

1. [CDCol](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/CDCol).
2. [Open Data Cube core](https://github.com/opendatacube/datacube-core.git). 
3. [Ingestor](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/ingestion-scheduler) cronjob. 

Run the script as follows

```sh 
bash ingestion_install.sh
```

If you need to keep instalation logs use **tee** to save **stdout** and **stderr**.

```sh
bash ingestion_install.sh 2>&1 | tee logs.txt
```