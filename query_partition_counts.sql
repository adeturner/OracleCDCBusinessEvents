set serveroutput on
DECLARE
  CURSOR c1 IS SELECT partition_name from target.partition_config;
  l_count number;
BEGIN
  FOR p IN c1
  LOOP
	EXECUTE IMMEDIATE 'SELECT count(*) FROM target.target_table1 partition (' || p.partition_name || ')' into l_count;
	dbms_output.put_line( p.partition_name || '=' || l_count );
  END LOOP;
END;
/