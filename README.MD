# Data Cube Instalation Scripts

## Cube User

Create the cube user in every machine:

* NFS
* DB
* WEB
* API
* Airflow Server
* Airflow Workers

```sh 
sudo adduser cubo
sudo usermod -aG sudo cubo
su cubo
cd
```

## Install NFS

Peform the following script. Replace **10.0.0.1/16** with the IPAddress of the WebServer, and **192.168.0.1/32** with the network and mask of the workers.

```sh 
bash nfs_install.sh 10.0.0.1/16 192.168.0.1/32
```

## Install DB

This script will

1. Install Postgres Database Manager System
2. Set the 'datacube' database
3. Set the 'airflow' database

Run the script as follows:

```sh 
bash db_install.sh
```

## Install Rest API

This script will install:

1. [CDCol](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/CDCol): modules that use the open datacube API for Colombian's needs.
2. [OpenDataCube](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/agdc-v2) (ODC) API from Australian Geoscience Data Cube v2.
3. RabbitMQ: It is an open source multi-protocol messaging broker.
4. [API Rest](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/api-rest): It exposes some features of the ODC through internet.

Run the script as follows:

```sh 
bash api_install.sh
```