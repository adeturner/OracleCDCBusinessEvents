BEGIN
	FOR Lcntr IN 1..1000
	LOOP
		INSERT INTO SOURCE.SOURCE_TABLE1 (ID, NAME, VERSION) VALUES (source.source_table1_seq.nextval, dbms_random.string(opt=>'A', len=>20), 1);
		commit;
	END LOOP;
END;
/
