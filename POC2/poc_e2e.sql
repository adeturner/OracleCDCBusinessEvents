
set serveroutput on lines 2000 pages 1000 trimspool on feedback off

spool output_poc1_e2e.lst

exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** poc_e2e.sql ***' );
exec dbms_output.put_line(CHR(10));

exec dbms_output.put_line( 'INFO test_reset: update poc_pkg...' );
@poc_pkg.sql

!$POC_HOME/ogg/ogg_start.sh
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
!$POC_HOME/ogg/ogg_start.sh
exec dbms_output.put_line( 'INFO test_reset: wait for OGG to start...' );
exec sys.dbms_session.sleep(15);

exec dbms_output.put_line( 'INFO test_data: insert single customer with details' );
exec source.testdata_pkg.insert_testdata

exec dbms_output.put_line( 'INFO test_data: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'INFO test_data: split partitions' );
@partition_split

exec dbms_output.put_line( 'INFO test_data: insert single customer with details' );
exec source.testdata_pkg.insert_testdata

exec dbms_output.put_line( 'INFO test_data: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'INFO test_data: split partitions' );
@partition_split

exec dbms_output.put_line( 'INFO test_data: insert single customer with details' );
exec source.testdata_pkg.insert_testdata
exec dbms_output.put_line( 'INFO test_data: update first customer' );
exec source.testdata_pkg.update_testdata(1)


exec dbms_output.put_line( 'INFO test_data: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'INFO test_data: split partitions' );
@partition_split

exec dbms_output.put_line( 'INFO poc_e2e: query the result' );
@source_query
@partition_query

@gen_masterdata.sql
@gen_masterdata_json.sql

spool off;