

BEGIN
	FOR Lcntr IN 1..5
	LOOP
		update SOURCE.SOURCE_TABLE1 set VERSION=VERSION+1 WHERE rowid = (select min(rowid) from SOURCE.SOURCE_TABLE1);
		update SOURCE.SOURCE_TABLE2 set VERSION=VERSION+1 WHERE rowid = (select min(rowid) from SOURCE.SOURCE_TABLE2);
		update SOURCE.SOURCE_TABLE3 set VERSION=VERSION+1 WHERE rowid = (select min(rowid) from SOURCE.SOURCE_TABLE3);
		commit;

	END LOOP;

	dbms_output.put_line( 'testdata_10rows_upd: rows updated ok' );

exception
	when others then	
		dbms_output.put_line( 'testdata_10rows_upd: unexpected exception' );
		raise;
END;
/
