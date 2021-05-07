alter session set container=ORCLPDB1;

CREATE USER source IDENTIFIED BY source;
GRANT CONNECT, RESOURCE, DBA TO source;
GRANT SELECT ANY DICTIONARY to source;
ALTER USER source DEFAULT TABLESPACE users;

CREATE USER target IDENTIFIED BY target;
GRANT CONNECT, RESOURCE, DBA TO target;
GRANT SELECT ANY DICTIONARY to target;
ALTER USER target DEFAULT TABLESPACE users;

CREATE PUBLIC DATABASE LINK source_link CONNECT TO source IDENTIFIED BY source USING 'ORCLPDB1';
CREATE PUBLIC DATABASE LINK target_link CONNECT TO target IDENTIFIED BY target USING 'ORCLPDB1';

select 'source ok' from dual@source_link
union
select 'target ok' from dual@target_link
/
