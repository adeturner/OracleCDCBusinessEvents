
set serveroutput on lines 2000 pages 1000 trimspool on
exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** partition_query.sql ***' );

col table_owner form a20
col table_name form a20
col partition_name form a20
SELECT table_owner, table_name, partition_name, high_value
from dba_tab_partitions 
where table_owner = 'TARGET'
and table_name like 'TARGET_TABLE%';

exec dbms_output.put_line(CHR(10));

set serveroutput on
DECLARE
  CURSOR c1 IS 
    SELECT table_owner, table_name, partition_name
    from dba_tab_partitions 
    where table_owner = 'TARGET'
    and table_name like 'TARGET_TABLE%';
  l_count number;
  l_name varchar2(200);
  str varchar2(2000);
BEGIN
  FOR p IN c1
  LOOP

    str := 'SELECT ''' || p.table_name || '.' || p.partition_name || ''', count(*) ' || 
      'FROM ' || p.table_owner || '.' || p.table_name || ' partition (' || p.partition_name || ')';

    -- dbms_output.put_line( str );  

	  EXECUTE IMMEDIATE str into l_name, l_count;
    dbms_output.put_line( l_name || '=' || to_char(l_count) );  
    
  END LOOP;
END;
/
