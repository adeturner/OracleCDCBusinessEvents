

set serveroutput on lines 2000 pages 1000 trimspool on feedback off

col master_pk form a10
col childL1_pk_col form a10
col childL2_pk_col form a10
col master_table form a10

select * from TARGET.SCHEMA_METADATA order by child_level, master_table;
