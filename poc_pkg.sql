CREATE OR REPLACE PACKAGE target.poc_pkg AS 
   PROCEDURE CREATE_PARTITION; 
END poc_pkg; 
/
show errors


CREATE OR REPLACE PACKAGE BODY target.poc_pkg AS 

	procedure create_partition
	is
	   partition_number number;
	   old_partition_name varchar2(20);
	   new_partition_name varchar2(20);
	   l_module varchar2(20);
	   l_partition_name varchar2(20);
	   l_current_scn number;
	   l_begin_scn number;
	   l_end_scn number;
	   l_newno number;
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

		dbms_output.put_line('Getting current SCN from source');
		select current_scn into l_current_scn from v$database@source_link;
		
		l_newno := target.partition_seq.nextval;
		old_partition_name:='PART_'|| to_char(l_newno-1);
		new_partition_name:='PART_'|| to_char(l_newno);

		dbms_output.put_line('Splitting partition at SCN=' || l_current_scn || ' with new partition=' || new_partition_name);
		execute immediate 
		   'ALTER TABLE target.target_table1 split  PARTITION "'||old_partition_name||
		   '" at ('||l_current_scn||') into (partition "'||old_partition_name||'" ,PARTITION "'||new_partition_name||'")';				

		
		insert into target.partition_config(module_name, partition_name, begin_scn, end_scn) values (l_module, new_partition_name, l_current_scn, null);
		
		update target.partition_config 
		set end_scn = l_current_scn-1
		where module_name = l_module
		and partition_name = old_partition_name;
		
		commit;
		
		dbms_output.put_line('DML to partition_config are complete');

	-- exception
	-- 	when others then
	-- 	  dbms_output.put_line('Unhandled exception.');

	end;

end poc_pkg;
/
show errors
