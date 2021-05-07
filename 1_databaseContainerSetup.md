# Oracle Database Container Setup

## install docker client

Follow https://docs.docker.com/docker-for-windows/wsl/

## set memory limit on wsl2

notepad C:\Users\<user>\.wslconfig

[wsl2]
memory=4GB   # Limits VM memory in WSL 2 up to 3GB
processors=4 # Makes the WSL 2 VM use two virtual processors

wsl --shutdown

restart docker desktop

## just for information about oracle enterprise db on docker

https://container-registry.oracle.com/pls/apex/f?p=113:4:109318438803394:::4:P4_REPOSITORY,AI_REPOSITORY,AI_REPOSITORY_NAME,P4_REPOSITORY_NAME,P4_EULA_ID,P4_BUSINESS_AREA_ID:9,9,Oracle%20Database%20Enterprise%20Edition,Oracle%20Database%20Enterprise%20Edition,1,0&cs=3xcKsg6fc98cu4qVZo7G7DZC0px6Pk4OqwZbujP-WFaaQTKU-dokjEMwLN2Q4B0NraK6htQsJXdJLM5JFn0p1_A

```text
docker run -d --name <container_name> \
 -p <host_port>:1521 -p <host_port>:5500 \
 -e ORACLE_SID=<your_sid> \
 -e ORACLE_PDB=<your_pdbname> \
 -e ORACLE_PWD=<your_database_password> \
 -e INIT_SGA_SIZE=<your_database_sga_memory_mb> \
 -e INIT_PGA_SIZE=<your_database_pga_memory_mb> \
 -e ORACLE_EDITION=<your_database_edition> \ 
 -e ORACLE_CHARACTERSET=<your_character_set> \
 -v [<host_mount_point>:]/opt/oracle/oradata \
container-registry.oracle.com/database/enterprise:19.3.0.0

Parameters:
 --name:                 The name of the container (default: auto generated
 -p:                     The port mapping of the host port to the container port.
                         Two ports are exposed: 1521 (Oracle Listener), 5500 (OEM Express)
 -e ORACLE_SID:          The Oracle Database SID that should be used (default:ORCLCDB)
 -e ORACLE_PDB:          The Oracle Database PDB name that should be used (default: ORCLPDB1)
 -e ORACLE_PWD:          The Oracle Database SYS, SYSTEM and PDBADMIN password (default: auto generated)
 -e INIT_SGA_SIZE:       The total memory in MB that should be used for all SGA components (optional)
 -e INIT_PGA_SIZE:       The target aggregate PGA memory in MB that should be used for all server processes attached to the instance (optional)
 -e ORACLE_EDITION:      The Oracle Database Edition (enterprise/standard, default: enterprise)
 -e ORACLE_CHARACTERSET: The character set to use when creating the database (default: AL32UTF8)
 -v /opt/oracle/oradata
                         The data volume to use for the database. Has to be writable by the Unix "oracle" (uid: 54321) user inside the container
                         If omitted the database will not be persisted over container recreation.
 -v /opt/oracle/scripts/startup | /docker-entrypoint-initdb.d/startup
                         Optional: A volume with custom scripts to be run after database startup.
                         For further details see the "Running scripts after setup and on
                         startup" section below.
 -v /opt/oracle/scripts/setup | /docker-entrypoint-initdb.d/setup
                         Optional: A volume with custom scripts to be run after database setup.
                         For further details see the "Running scripts after setup and on startup" section below.
```

## get database docker container

You might get "Error response from daemon: pull access denied for container-registry.oracle.com/enterprise, repository does not exist or may require 'docker login': denied: requested access to the resource is denied"

First you need to login to container-registry.oracle.com and accept the T&Cs for the image. you have 8 hours from then to pull
https://container-registry.oracle.com/pls/apex/f?p=113:4:115266506095943

Once you have accepted the T&Cs:

```code
docker login -u forename.surname@company.com container-registry.oracle.com
docker pull container-registry.oracle.com/database/enterprise:latest

docker run -d --name ORADB -p 1521:1521 -p 5500:5500 -e ORACLE_PWD=password1 -v /home/username/oradata:/opt/oracle/oradata container-registry.oracle.com/database/enterprise:latest

# docker exec -it ORADB /bin/bash
```

## get instant client

```code
wget https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-sqlplus-linux.x64-21.1.0.0.0.zip
wget https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basiclite-linux.x64-21.1.0.0.0.zip
cd ~
unzip instantclient*

sudo sh -c "echo /opt/oracle/instantclient_21_1 > /etc/ld.so.conf.d/oracle-instantclient.conf"
sudo ldconfig

export LD_LIBRARY_PATH=~/instantclient_21_1:$LD_LIBRARY_PATH
```
