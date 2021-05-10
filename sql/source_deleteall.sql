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
    str varchar2(2000);
    l_continue boolean;
    l_rowcount number;
BEGIN

  l_continue := true;

  WHILE l_continue
  LOOP

      l_continue := false;

      FOR p IN c1
      LOOP
          str := 'SELECT count(*) FROM ' || p.owner || '.' || p.table_name;
          execute immediate str into l_rowcount;

          if l_rowcount > 0 then

              str := 'DELETE FROM ' || p.owner || '.' || p.table_name;
              dbms_output.put_line( l_rowcount || ' rows to ' || str );  

              begin
                  EXECUTE IMMEDIATE str;
                  dbms_output.put_line( 'Delete from ' || p.owner || '.' || p.table_name || ' completed'  );  
              exception
                  when others then 
                      l_continue := true;
                      dbms_output.put_line( 'Delete from ' || p.owner || '.' || p.table_name || ' failed'  );  
              end;

        end if;
          
      END LOOP;
  END LOOP;

END;
/

commit;