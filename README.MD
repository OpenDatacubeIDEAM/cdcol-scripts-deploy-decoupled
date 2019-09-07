# Data Cube Instalation Scripts

The repository contains instalation scripts for: NFS, DB, WEB, API, Airflow Server, Airflow Workers.

## Install NFS

The NFS instalation script will settup /web_storage, /dc_storage and /source_storage share directories.

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

1. The command ```datacube -v system int``` fails as follows. The problem was fixed downgrading sqlalchemy to versión 1.1.18, using ```pip install sqlalchemy==1.1.18```. The same solution is suggested on [this issue](https://github.com/opendatacube/datacube-core/issues/667). 

```sh 
Initialising database...
Updated.
Checking indexes/views.
Error Connecting to database: (psycopg2.ProgrammingError) function agdc.common_timestamp(text) does not exist
LINE 1: ...a_type_id, agdc.dataset.metadata AS metadata_doc, "agdc.comm...
                                                             ^
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.

[SQL: CREATE VIEW agdc.dv_eo_dataset AS SELECT agdc.dataset.id AS id, agdc.dataset.added AS indexed_time, agdc.dataset.added_by AS indexed_by, agdc.dataset_type.name AS product, agdc.dataset.dataset_type_ref AS dataset_type_id, agdc.metadata_type.name AS metadata_type, agdc.dataset.metadata_type_ref AS metadata_type_id, agdc.dataset.metadata AS metadata_doc, "agdc.common_timestamp"(agdc.dataset.metadata #>> '{creation_dt}') AS creation_time, agdc.dataset.metadata #>> '{format, name}' AS format, agdc.dataset.metadata #>> '{ga_label}' AS label, "agdc.float8range"(least(CAST(agdc.dataset.metadata #>> '{extent, coord, ur, lat}' AS DOUBLE PRECISION), CAST(agdc.dataset.metadata #>> '{extent, coord, lr, lat}' AS DOUBLE PRECISION), CAST(agdc.dataset.metadata #>> '{extent, coord, ul, lat}' AS DOUBLE PRECISION), CAST(agdc.dataset.metadata #>> '{extent, coord, ll, lat}' AS DOUBLE PRECISION)), greatest(CAST(agdc.dataset.metadata #>> '{extent, coord, ur, lat}' AS DOUBLE PRECISION), CAST(agdc.dataset.metadata #>> '{extent, coord, lr, lat}' AS DOUBLE PRECISION), CAST(agdc.dataset.metadata #>> '{extent, coord, ul, lat}' AS DOUBLE PRECISION), CAST(agdc.dataset.metadata #>> '{extent, coord, ll, lat}' AS DOUBLE PRECISION)), '[]') AS lat, "agdc.float8range"(least(CAST(agdc.dataset.metadata #>> '{extent, coord, ul, lon}' AS DOUBLE PRECISION), CAST(agdc.dataset.metadata #>> '{extent, coord, ur, lon}' AS DOUBLE PRECISION), CAST(agdc.dataset.metadata #>> '{extent, coord, ll, lon}' AS DOUBLE PRECISION), CAST(agdc.dataset.metadata #>> '{extent, coord, lr, lon}' AS DOUBLE PRECISION)), greatest(CAST(agdc.dataset.metadata #>> '{extent, coord, ul, lon}' AS DOUBLE PRECISION), CAST(agdc.dataset.metadata #>> '{extent, coord, ur, lon}' AS DOUBLE PRECISION), CAST(agdc.dataset.metadata #>> '{extent, coord, ll, lon}' AS DOUBLE PRECISION), CAST(agdc.dataset.metadata #>> '{extent, coord, lr, lon}' AS DOUBLE PRECISION)), '[]') AS lon, tstzrange(least("agdc.common_timestamp"(agdc.dataset.metadata #>> '{extent, from_dt}'), "agdc.common_timestamp"(agdc.dataset.metadata #>> '{extent, center_dt}')), greatest("agdc.common_timestamp"(agdc.dataset.metadata #>> '{extent, to_dt}'), "agdc.common_timestamp"(agdc.dataset.metadata #>> '{extent, center_dt}')), '[]') AS time, agdc.dataset.metadata #>> '{platform, code}' AS platform, agdc.dataset.metadata #>> '{instrument, name}' AS instrument, agdc.dataset.metadata #>> '{product_type}' AS product_type 
FROM agdc.dataset JOIN agdc.dataset_type ON agdc.dataset_type.id = agdc.dataset.dataset_type_ref JOIN agdc.metadata_type ON agdc.metadata_type.id = agdc.dataset_type.metadata_type_ref 
WHERE agdc.dataset.archived IS NULL AND agdc.dataset.metadata_type_ref = 1]
(Background on this error at: http://sqlalche.me/e/f405)
```

2. After downgrade python using  ```conda install python=3.6.8``` or install a package from another channel ```conda install -c conda-forge```. The following error was produced.

```sh
conda info

Traceback (most recent call last):
  File "~/anaconda/bin/conda", line 3, in <module>
    from conda.cli import main
ImportError: No module named conda.cli
```

I solve this problem installing the version 4.6.14 of conda as suggested on this issue [9004](https://github.com/conda/conda/issues/9004) before perform further installs.

`conda install conda=4.6.14
`

It looks like further versions of conda are introducing this error.
