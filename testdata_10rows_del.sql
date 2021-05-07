

BEGIN
	FOR Lcntr IN 1..10
	LOOP
		delete from SOURCE.SOURCE_TABLE2 WHERE rowid = (select min(rowid) from SOURCE.SOURCE_TABLE2);
		delete from SOURCE.SOURCE_TABLE3 WHERE rowid = (select min(rowid) from SOURCE.SOURCE_TABLE3);
		commit;

	END LOOP;

	dbms_output.put_line( 'testdata_10rows_del: rows deleted ok' );

exception
	when others then	
		dbms_output.put_line( 'testdata_10rows_del: unexpected exception' );
		raise;
END;
/
