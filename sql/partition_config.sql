set serveroutput on lines 2000 pages 1000 trimspool on
exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** partition_config.sql ***' );
exec dbms_output.put_line(CHR(10));

select * from target.partition_config order by begin_scn;


