CREATE OR REPLACE PACKAGE target.poc_pkg AS 
    PROCEDURE split_partitions; 
    procedure gen_master_data (partname varchar2, start_scn number, end_scn number);
END poc_pkg; 
/
show errors

CREATE OR REPLACE PACKAGE BODY target.poc_pkg AS 

	procedure split_partitions
	is
	   partition_number number;
	   old_partition_name varchar2(20);
	   new_partition_name varchar2(20);
	   l_module varchar2(20);
	   l_partition_name varchar2(20);
	   l_current_scn number;
	   l_begin_scn number;
	   l_end_scn number;
	   l_max_scn number;

       CURSOR c1 IS 
         SELECT distinct table_name
         from dba_tab_partitions 
         where table_owner = 'TARGET'
         and table_name like '%';

	begin
	
		l_module := 'POC';
		
		begin
			dbms_output.put_line('Getting partitionc config');
			select partition_name, begin_scn, end_scn 
			into l_partition_name, l_begin_scn, l_end_scn 
			from target.partition_config 
			where module_name = l_module
			and   end_scn is null;
			
		exception

			when NO_DATA_FOUND then
			
				dbms_output.put_line('Partition config missing, inserting seed data');
				insert into target.partition_config(module_name, partition_name, begin_scn, end_scn) values ('POC', 'PART_0', 0, null);
				commit;
				
				select partition_name, begin_scn, end_scn 
				into l_partition_name, l_begin_scn, l_end_scn 
				from target.partition_config 
				where module_name = l_module
				and   end_scn is null;

		end;

		select current_scn into l_current_scn from v$database@source_link;
		dbms_output.put_line('Current SCN=' || l_current_scn);
		
		SELECT max(begin_scn) into l_max_scn from target.partition_config;
		dbms_output.put_line('Max partition_config SCN=' || l_max_scn);

		old_partition_name:='PART_'|| to_char(l_max_scn);
		new_partition_name:='PART_'|| to_char(l_current_scn);

		FOR p IN c1
		LOOP

			dbms_output.put_line('Splitting ' || p.table_name || ' partition at SCN=' || l_current_scn || ' with old partition=' || old_partition_name || ' and new partition=' || new_partition_name);

			execute immediate 
					'ALTER TABLE target.' || p.table_name || ' split  PARTITION "'||old_partition_name||
					'" at ('||l_current_scn||') into (partition "'||old_partition_name||'" ,PARTITION "'||new_partition_name||'")';				
		END LOOP;

		insert into target.partition_config(module_name, partition_name, begin_scn, end_scn) values (l_module, new_partition_name, l_current_scn, null);
		
		update target.partition_config 
		set end_scn = l_current_scn-1
		where module_name = l_module
		and partition_name = old_partition_name;
		
		commit;
		
		dbms_output.put_line('DML to partition_config are complete');

	exception
		when others then
	 	  dbms_output.put_line('Unhandled exception');
		raise;

	end split_partitions;
	

	procedure gen_master_data (partname varchar2, start_scn number, end_scn number)
	is
		cursor c_target1 (startscn number, endscn number) is
		select rid, max(scnno) scnno from target.target_table1 where SCNNO between startscn and endscn group by rid order by 2;

		cursor c_target2 (startscn number, endscn number) is
		select rid, max(scnno) scnno from target.target_table2 where SCNNO between startscn and endscn group by rid order by 2;

		cursor c_target3 (startscn number, endscn number) is
		select rid, max(scnno) scnno from target.target_table3 where SCNNO between startscn and endscn group by rid order by 2;

		str varchar2(2000);
	begin

		dbms_output.put_line(CHR(10) || 'Processing:' || partname || ' begin_scn=' || start_scn || ', end_scn=' || end_scn || ':');

		-- empty the master partition
		execute immediate ('alter table target.MASTER_SOURCE_TABLE1 truncate partition ' || partname);

		/*
		For each rowid that is updated we want to get the max(scnno), and then look back to the source_table at that SCN
		It seems you cannot dynamically assign bind vars to the SCN in a flashback query, so we have to do row by row dynamic sql
		Our aim is to generate a unique list of business object masters, i.e. source_table1 {rids, max(scn)}
		Get the max scn for each row id (we only need the last one in the time period)
		If it was a deletion we will see zero rows from these queries, so we have to look back one SCN to get the parent change logged
		Duplicates dont matter at this point, because we remove them in the next step

		for each target_tableN get the set {rid, max(scn) as target_scn}
			join back up to get the business object master
			insert into master_source_table
			select s1.rid, target_scn from source_table1 s1, source_tableN n where s1.pk = n.fk at both scn, and scn-1
		end
		*/

		-- parent table: SOURCE_TABLE1
		FOR r in c_target1 (start_scn, end_scn) 
		LOOP
			str := '
				insert into target.master_source_table1 (rid, scnno)
				select rowid, ' || r.scnno || ' 
				from source.source_table1@source_link as of scn ' || r.scnno || ' t1
				where t1.rowid = ''' || r.rid || '''
				union
				select rowid, ' || r.scnno || ' 
				from source.source_table1@source_link as of scn ' || to_char(r.scnno-1) || ' t1
				where t1.rowid = ''' || r.rid || '''
			';

			-- dbms_output.put_line(str);
			execute immediate str;
		END LOOP;
		commit;

		-- child table: SOURCE_TABLE2
		FOR r in c_target2 (start_scn, end_scn)
		LOOP
			str := '
				insert into target.master_source_table1 (rid, scnno)
				select t1.rowid, ' || r.scnno || ' 
				from source.source_table1@source_link as of scn ' || r.scnno || ' t1,
					source.source_table2@source_link as of scn ' || r.scnno || ' t2
				where t2.rowid = ''' || r.rid || '''
				and   t1.id = t2.source_table1_id
				union
				select t1.rowid, ' || r.scnno || ' 
				from source.source_table1@source_link as of scn ' || r.scnno || ' t1,
					source.source_table2@source_link as of scn ' || to_char(r.scnno-1) || ' t2
				where t2.rowid = ''' || r.rid || '''
				and   t1.id = t2.source_table1_id
			';

			-- dbms_output.put_line(str);
			execute immediate str;
		END LOOP;
		commit;

		-- child table: SOURCE_TABLE3
		FOR r in c_target3 (start_scn, end_scn)
		LOOP
			str := '
				insert into target.master_source_table1 (rid, scnno)
				select t1.rowid, ' || r.scnno || ' 
				from source.source_table1@source_link as of scn ' || r.scnno || ' t1,
					source.source_table3@source_link as of scn ' || r.scnno || ' t3
				where t3.rowid = ''' || r.rid || '''
				and   t1.id = t3.source_table1_id
				union
				select t1.rowid, ' || r.scnno || ' 
				from source.source_table1@source_link as of scn ' || r.scnno || ' t1,
					source.source_table3@source_link as of scn ' || to_char(r.scnno-1) || ' t3
				where t3.rowid = ''' || r.rid || '''
				and   t1.id = t3.source_table1_id
			';

			-- dbms_output.put_line(str);
			execute immediate str;
		END LOOP;
		commit;

	end gen_master_data;

end poc_pkg;
/
show errors
