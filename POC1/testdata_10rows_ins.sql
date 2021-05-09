BEGIN
	FOR Lcntr IN 1..10
	LOOP
		INSERT INTO SOURCE.SOURCE_TABLE1 (ID, NAME, VERSION) VALUES (source.source_table1_seq.nextval, dbms_random.string(opt=>'A', len=>20), 1);
		INSERT INTO SOURCE.SOURCE_TABLE2 (ID, SOURCE_TABLE1_ID, NAME, VERSION) VALUES (source.source_table2_seq.nextval, source.source_table1_seq.currval, dbms_random.string(opt=>'A', len=>20), 1);
		INSERT INTO SOURCE.SOURCE_TABLE3 (ID, SOURCE_TABLE1_ID, NAME, VERSION) VALUES (source.source_table3_seq.nextval, source.source_table1_seq.currval, dbms_random.string(opt=>'A', len=>20), 1);
		commit;

	END LOOP;

	dbms_output.put_line( 'testdata_10rows_ins: rows inserted ok' );

exception
	when others then	
		dbms_output.put_line( 'testdata_10rows_ins: unexpected exception' );
		raise;
END;
/
