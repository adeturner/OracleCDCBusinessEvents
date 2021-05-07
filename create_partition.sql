set serveroutput on lines 132 pages 1000

exec target.poc_pkg.create_partition

select * from target.partition_config;
select partition_name from dba_tab_partitions where table_owner = 'TARGET' and table_name = 'TARGET_TABLE1';

# useful statements during development
# select * from dba_sequences where sequence_owner = 'TARGET';
# drop sequence target.partition_seq;
# create sequence target.partition_seq start with 1;
# insert into target.partition_config(module_name, partition_name, begin_scn, end_scn) values ('POC', 'PART_1', 2323194, null);
