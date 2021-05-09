# Oracle Goldengate Container Setup

## install ogg in the container

Download binaries locally from https://www.oracle.com/uk/middleware/technologies/goldengate-downloads.html

Unzip on windows so you can access from /mnt/c in wsl

Note there is a permissions bug which needs fixing from inside wsl

```code
chmod +rx stage/ext/jlib/version4j.jar
```

## Create response file for install

Copy and edit fbo_ggs_Linux_x64_shiphome/Disk1/response/oggcore.rsp 

```code
vi /opt/oracle/oradata/ogg/oggcore.rsp

oracle.install.responseFileVersion=/oracle/install/rspfmt_ogginstall_response_schema_v19_1_0
INSTALL_OPTION=ORA19c
SOFTWARE_LOCATION=/opt/oracle/product/ogg19
INVENTORY_LOCATION=/opt/oracle/oraInventory
UNIX_GROUP_NAME=dba

# run installer in the container
./runInstaller -silent -showProgress -waitforcompletion -responseFile /opt/oracle/oradata/ogg/oggcore.rsp

# Put the following in .bashrc:
export OGG_HOME=/opt/oracle/product/ogg19
export PATH=/opt/oracle/product/ogg19/bin:$PATH
```

## setup ogg in ORCLCDB

Follow https://docs.oracle.com/en/middleware/goldengate/core/19.1/oracle-db/configuring-oracle-goldengate-multitenant-container-database-1.html#GUID-26AFC906-E67D-448E-93EC-FE2A54679793

## Enable archivelog

This turns out to be hard because when you stop the database it stops the container. One way is to edit the startup file

```code
cd $ORACLE_BASE
cp startDB.sh startDB.sh.orig
edit startDB.sh to add: alter database archivelog

$ diff startDB.sh startDB.sh.archivelogenable
60c60
<    -- alter database archivelog;
---
>    alter database archivelog;
```

Restart the container, then edit the file again to remove the alter database command

## CDB level

```code
sqlplus sys/password1@//localhost:1521/ORCLCDB as sysdba

ALTER SYSTEM SET log_archive_dest_1='LOCATION=/opt/oracle/oradata/ORCLCDB/arch' scope=both;
ALTER DATABASE FORCE LOGGING;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
ALTER SYSTEM SWITCH LOGFILE;
alter system set ENABLE_GOLDENGATE_REPLICATION=true scope=both;
-- alter system set UNDO_MANAGEMENT=AUTO scope=both;
alter system set UNDO_RETENTION=86400 scope=both;

create user c##ggadmin identified by password1 default tablespace users;
exec dbms_goldengate_auth.grant_admin_privilege('C##GGADMIN',container=>'all')
grant dba to c##ggadmin
```

## PDB level

```code
sqlplus sys/password1@//localhost:1521/ORCLCDB as sysdba

alter session set container=ORCLPDB1;

create user OGG_APPLY identified by password1;
grant create session to OGG_APPLY;
begin
DBMS_GOLDENGATE_AUTH.GRANT_ADMIN_PRIVILEGE(
grantee => 'OGG_APPLY', 
privilege_type => 'APPLY',
container => 'ORCLPDB1');
end;
/
```

## setup ogg filesystem

```code
ogg/ogg_init.sh
```

