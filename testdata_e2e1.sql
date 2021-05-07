
set serveroutput on lines 2000 pages 1000 trimspool on feedback off
exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** testdata_e2e_test1.sql ***' );
exec dbms_output.put_line(CHR(10));

exec dbms_output.put_line( 'e2e_test1: reset test data' );
@testdata_reset

exec dbms_output.put_line( 'e2e_test1: insert 10 rows' );
@testdata_10rows_ins.sql

exec dbms_output.put_line( 'e2e_test1: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'e2e_test1: split partitions' );
@partition_split

exec dbms_output.put_line( 'e2e_test1: insert 10 rows' );
@testdata_10rows_ins.sql

exec dbms_output.put_line( 'e2e_test1: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'e2e_test1: split partitions' );
@partition_split

exec dbms_output.put_line( 'e2e_test1: update 10 rows' );
@testdata_10rows_upd.sql

exec dbms_output.put_line( 'e2e_test1: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'e2e_test1: delete 10 child rows' );
@testdata_10rows_del.sql

exec dbms_output.put_line( 'e2e_test1: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'e2e_test1: split partitions' );
@partition_split

exec dbms_output.put_line( 'e2e_test1: query the result' );
@source_query
@partition_query


-- testdata_e2e1

/*

TARGET_TABLE1.PART_0=0
TARGET_TABLE1.PART_2540814=10
TARGET_TABLE1.PART_2541208=10
TARGET_TABLE1.PART_2541389=10
TARGET_TABLE1.PART_2541622=0
TARGET_TABLE2.PART_0=0
TARGET_TABLE2.PART_2540814=10
TARGET_TABLE2.PART_2541208=10
TARGET_TABLE2.PART_2541389=20
TARGET_TABLE2.PART_2541622=0
TARGET_TABLE3.PART_0=0
TARGET_TABLE3.PART_2540814=10
TARGET_TABLE3.PART_2541208=10
TARGET_TABLE3.PART_2541389=20
TARGET_TABLE3.PART_2541622=0

*/