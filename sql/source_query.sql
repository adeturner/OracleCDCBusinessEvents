set serveroutput on lines 2000 pages 1000 trimspool on
exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** source_query.sql ***' );

exec dbms_output.put_line(CHR(10));

set serveroutput on
DECLARE
  CURSOR c1 IS 
    SELECT owner, table_name
    from dba_tables
    where owner = 'SOURCE'
    and table_name like '%';
  l_count number;
  l_name varchar2(200);
  str varchar2(2000);
BEGIN
  FOR p IN c1
  LOOP

    str := 'SELECT ''' || p.table_name || ''', count(*) ' || 
      'FROM ' || p.owner || '.' || p.table_name;

    EXECUTE IMMEDIATE str into l_name, l_count;
    dbms_output.put_line( l_name || '=' || to_char(l_count) );  
    
  END LOOP;
END;
/
