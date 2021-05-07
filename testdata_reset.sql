set serveroutput on lines 2000 pages 1000 trimspool on feedback off
exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** testdata_reset.sql ***' );
exec dbms_output.put_line(CHR(10));

@source_deleteall
@partition_split

exec dbms_output.put_line( 'testdata_reset: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(15);

@partition_split
@partition_reset

exec dbms_output.put_line( 'testdata_reset: split partition now to avoid writing to PART_0');
@partition_split

@partition_query
@source_query
!./ogg_check.sh


