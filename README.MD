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
./nfs_install.sh 10.0.0.1/16 192.168.0.1/32
```

## Install DB

```sh 
./db_install.sh
```

