
set serveroutput on lines 2000 pages 1000 trimspool on feedback off

spool output_poc_e2e.lst

exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** testdata_e2e_test1.sql ***' );
exec dbms_output.put_line(CHR(10));

exec dbms_output.put_line( 'INFO test_reset: update poc_pkg...' );
@poc_pkg.sql

!./ogg_start.sh
exec dbms_output.put_line( 'INFO test_reset: wait for OGG to start...' );
exec sys.dbms_session.sleep(15);

exec dbms_output.put_line( 'INFO test_reset: reset source data' );
@source_deleteall

exec dbms_output.put_line( 'INFO test_reset: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(15);

exec dbms_output.put_line( 'INFO test_reset: split to get empty lead partition' );
@partition_split

exec dbms_output.put_line( 'INFO test_reset: partition reset...' );
@partition_reset

exec dbms_output.put_line( 'INFO test_reset: split partition now to avoid writing to PART_0');
@partition_split

-- be sure ogg is started
!./ogg_start.sh
exec dbms_output.put_line( 'INFO test_reset: wait for OGG to start...' );
exec sys.dbms_session.sleep(15);

exec dbms_output.put_line( 'INFO test_data: insert 10 rows' );
@testdata_10rows_ins.sql

exec dbms_output.put_line( 'INFO test_data: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'INFO test_data: split partitions' );
@partition_split

exec dbms_output.put_line( 'INFO test_data: insert 10 rows' );
@testdata_10rows_ins.sql

exec dbms_output.put_line( 'INFO test_data: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'INFO test_data: split partitions' );
@partition_split

exec dbms_output.put_line( 'INFO test_data: update 10 rows' );
@testdata_10rows_upd.sql

exec dbms_output.put_line( 'INFO test_data: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'INFO test_data: delete 10 child rows' );
@testdata_10rows_del.sql

exec dbms_output.put_line( 'INFO test_data: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'INFO test_data: split partitions' );
@partition_split

exec dbms_output.put_line( 'INFO poc_e2e: query the result' );
@source_query
@partition_query

@generate_json.sql

spool off;