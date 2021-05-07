
set serveroutput on lines 2000 pages 1000 trimspool on feedback off
exec dbms_output.put_line( '*** partition_reset.sql ***' );

@partition_drop
@partition_config
@partition_query


