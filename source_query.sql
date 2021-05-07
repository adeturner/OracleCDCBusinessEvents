set serveroutput on lines 2000 pages 1000 trimspool on
exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** source_query.sql ***' );

select 'SOURCE_TABLE1', count(*) from source.source_table1
union
select 'SOURCE_TABLE2', count(*) from source.source_table2
union
select 'SOURCE_TABLE3', count(*) from source.source_table3;
