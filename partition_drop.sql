
set serveroutput on lines 2000 pages 1000 trimspool on
exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** partition_drop.sql ***' );

DECLARE
  CURSOR c1 IS 
    SELECT table_name, partition_name
    from dba_tab_partitions 
    where table_owner = 'TARGET'
    and (table_name like 'TARGET_TABLE%' or table_name like 'COPY_%');
  l_count number;
  l_name varchar2(2);
BEGIN
  FOR p IN c1
  LOOP
    begin
        EXECUTE IMMEDIATE 'alter table target.' || p.table_name || ' DROP PARTITION ' || p.partition_name;
        dbms_output.put_line( 'Dropping partition target_table1.' || p.partition_name);
        exception
        when others then
        null;
    end;
  END LOOP;
END;
/

delete from target.partition_config where begin_scn != 0;
update target.partition_config set end_scn = null where begin_scn=0;
commit;


DECLARE
  CURSOR c1 IS 
    SELECT table_name, partition_name
    from dba_tab_partitions 
    where table_owner = 'TARGET'
    and (table_name like 'TARGET_TABLE%' or table_name like 'COPY_%');
  l_count number;
  l_name varchar2(2);
BEGIN
  FOR p IN c1
  LOOP
    begin
        dbms_output.put_line( 'Renaming partition target_table1.' || p.partition_name);
        if p.partition_name = 'PART_0' then
          EXECUTE IMMEDIATE 'alter table target.' || p.table_name || ' ADD PARTITION PART_0A VALUES LESS THAN (maxvalue) TABLESPACE USERS';
          EXECUTE IMMEDIATE 'alter table target.' || p.table_name || ' DROP PARTITION ' || p.partition_name;
          EXECUTE IMMEDIATE 'alter table target.' || p.table_name || ' RENAME PARTITION PART_0A TO PART_0';
        else
          EXECUTE IMMEDIATE 'alter table target.' || p.table_name || ' RENAME PARTITION ' || p.partition_name || ' TO PART_0';
        end if;
    exception
        when others then
        null;
    end;
  END LOOP;
END;
/

/*
alter table target.target_table1 add partition part_0a VALUES LESS THAN (maxvalue) TABLESPACE USERS;
alter table target.target_table2 add partition part_0a VALUES LESS THAN (maxvalue) TABLESPACE USERS;
alter table target.target_table3 add partition part_0a VALUES LESS THAN (maxvalue) TABLESPACE USERS;
alter table target.target_table1 drop partition part_0;
alter table target.target_table2 drop partition part_0;
alter table target.target_table3 drop partition part_0;
alter table target.target_table1 rename partition part_0a to part_0;
alter table target.target_table2 rename partition part_0a to part_0;
alter table target.target_table3 rename partition part_0a to part_0;
*/