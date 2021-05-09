alter session set container=ORCLPDB1;

-- testing in a container, but in reality users should be in two separate databases

CREATE USER source IDENTIFIED BY source;
GRANT CONNECT, RESOURCE, DBA TO source;
GRANT SELECT ANY DICTIONARY to source;
ALTER USER source DEFAULT TABLESPACE users;

CREATE USER target IDENTIFIED BY target;
GRANT CONNECT, RESOURCE, DBA TO target;
GRANT SELECT ANY DICTIONARY to target;
ALTER USER target DEFAULT TABLESPACE users;

