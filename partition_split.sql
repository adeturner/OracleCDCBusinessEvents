set serveroutput on lines 2000 pages 1000 trimspool on

exec dbms_output.put_line( '*** partition_split.sql ***' );
exec target.poc_pkg.split_partitions