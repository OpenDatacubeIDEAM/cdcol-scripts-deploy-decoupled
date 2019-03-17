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

Peform the following script. Replace **web_ip/mask** with the IPAddress and network mask of WebServer, and **WorkersNet/Mask** with the network and mask of the workers.

```sh 
bash nfs_install.sh web_ip/mask workers_net/mask
```

Example:

```sh 
bash nfs_install.sh 10.0.0.1/16 192.168.0.0/32
```

If you need to keep instalation logs use **tee** to save **stdout** and **stderr**.

```sh
bash nfs_install.sh web_ip/mask workers_net/mask > >(tee -a stdout.log) 2> >(tee -a stderr.log >&2)
```


## Install DB

This script will

1. Install Postgres Database Manager System
2. Set the 'datacube' database
3. Set the 'airflow' database
4. Install redis

Run the script as follows:

```sh 
bash db_install.sh
```

If you need to keep instalation logs use **tee** to save **stdout** and **stderr**.

```sh
bash db_install.sh > >(tee -a stdout.log) 2> >(tee -a stderr.log >&2)
```

To allow remote connections to the database perfom the following changes. Modify the file **postgresql.conf**.

```sh 
sudo nano /etc/postgresql/9.5/main/postgresql.conf

listen_addresses = '*'         # what IP address(es) to listen on;
```

Add the hosts allowed to connect to the database machine to the file **pg_hba.conf**. Where *172.24.99.0/24* is the network of the host allowed to connect to the database.

```sh 
sudo nano /etc/postgresql/9.5/main/pg_hba.conf

# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
host    all             all             172.24.99.0/24          md5
```

## Install Rest API

This script will install:

1. [CDCol](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/CDCol): modules that use the open datacube API for Colombian's needs.
2. [OpenDataCube](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/agdc-v2) (ODC) API from Australian Geoscience Data Cube v2.
3. RabbitMQ: It is an open source multi-protocol messaging broker.
4. [API Rest](https://gitlab.virtual.uniandes.edu.co/datacube-ideam/api-rest): It exposes some features of the ODC through internet.

Run the script as follows, replace

* db_ip: IP Adress database server
* nfs_ip: IP Adress nfs server 

```sh 
bash api_install.sh db_ip nfs_ip
```

If you need to keep instalation logs use **tee** to save **stdout** and **stderr**.

```sh
bash api_install.sh db_ip nfs_ip > >(tee -a stdout.log) 2> >(tee -a stderr.log >&2)
```