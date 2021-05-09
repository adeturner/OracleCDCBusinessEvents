set serveroutput on lines 2000 pages 1000 trimspool on
exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** source_deleteall.sql ***' );

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
    str := 'DELETE FROM ' || p.owner || '.' || p.table_name;
    dbms_output.put_line( str );  
    EXECUTE IMMEDIATE str;
    dbms_output.put_line( 'Delete from ' || p.owner || '.' || p.table_name || ' completed'  );  
    
  END LOOP;
END;
/

commit;