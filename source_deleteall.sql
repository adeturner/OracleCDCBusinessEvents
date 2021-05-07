set serveroutput on lines 2000 pages 1000 trimspool on
exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** source_deleteall.sql ***' );

delete from source.source_table3;
delete from source.source_table2;
delete from source.source_table1;
commit;