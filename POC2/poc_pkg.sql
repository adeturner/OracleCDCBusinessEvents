CREATE OR REPLACE PACKAGE target.poc_pkg AS 

    PROCEDURE split_partitions; 
    procedure gen_master_data (partname varchar2, start_scn number, end_scn number);
	procedure gen_master_data_json (start_scn number, end_scn number);

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
	

	procedure get_master_insert (master_table varchar2, outSqlString OUT varchar2) 
	IS
	begin
		-- /*+ opt_param(''cursor_sharing=force'') */
		outSqlString := 'insert  into target.MASTER_' || master_table || ' (optype, rid, scnno)
						 values (:optype, :rid, :scnno)';
	end get_master_insert;

	procedure get_master_select1 (
				optype IN varchar2, 
				master_table IN varchar2, 
				master_pk_col IN varchar2, 
				rid IN ROWID, 
				scnno IN number, 
				outSqlString OUT varchar2) 
	IS
	begin

		outSqlString := 'select ''' || optype || ''', master.rowid, :scnno
				from source.'|| master_table || '@source_link master
				where master.rowid = :rid';
	
	end get_master_select1;

	procedure get_master_select2 (
				optype IN varchar2, 
				master_table IN varchar2, 
				master_pk_col IN varchar2, 
				childL1_table IN varchar2, 
				childL1_fk_col IN varchar2, 
				rid IN ROWID, 
				scnno IN number, 
				outSqlString OUT varchar2) 
	is
	begin

		outSqlString := 
		       'select ''' || optype || ''', master.rowid, :scnno
				from source.'|| master_table || '@source_link  master,
					 source.' || childL1_table || '@source_link child
				where child.rowid = :rid
				and   master.' || master_pk_col || ' = child.' || childL1_fk_col;
	
	end get_master_select2;

	procedure get_master_select3 (
				optype IN varchar2, 
				master_table IN varchar2, 
				master_pk_col IN varchar2, 
				childL1_table IN varchar2, 
				childL1_pk_col IN varchar2, 
				childL1_fk_col IN varchar2, 
				childL2_table IN varchar2, 
				childL2_fk_col IN varchar2, 
				rid IN ROWID, 
				scnno IN number, 
				outSqlString OUT varchar2) 
	is
	begin
		-- 				where childL2.rowid = ''' || rid || '''

		outSqlString := 
		       'select ''' || optype || ''', master.rowid, :scnno
				from source.'|| master_table || '@source_link master,
					 source.' || childL1_table || '@source_link  childL1,
					 source.' || childL2_table || '@source_link childL2
				where childL2.rowid = :rid
				and   master.' || master_pk_col || ' = childL1.' || childL1_fk_col || '
				and   childL1.' || childL1_pk_col || ' = childL2.' || childL2_fk_col
				;
	
	end get_master_select3;

	procedure gen_master_data (partname varchar2, start_scn number, end_scn number)
	is

		c_master_table varchar2(100) := 'CUSTOMER';
		c_master_table_pk varchar2(100) := 'ID';

		cursor c_metadata is select * from TARGET.SCHEMA_METADATA order by child_level;
		r SYS_REFCURSOR;

		str varchar2(2000);
		str1 varchar2(2000);
		str2 varchar2(2000);
		tab varchar2(40);
		tmp varchar2(2000);
		l_optype char(1);
		l_rid ROWID;
		l_scnno number;

		-- mirror type for master_table
		TYPE t_rec IS RECORD (
			optype char(1),
			rid   ROWID, 
			SCNNO number);

		rec t_rec;
   		-- TYPE t_tab IS TABLE OF t_rec INDEX BY BINARY_INTEGER;

	begin

		dbms_output.put_line(CHR(10) || 'Processing:' || partname || ' start_scn=' || start_scn || ', end_scn=' || end_scn || ':');

		-- empty the master partition
		execute immediate ('delete from target.MASTER_CUSTOMER');
		commit;

		/*
		For each rowid that is updated we want to get the max(scnno), and then look back to the source_table at that SCN
		It seems you cannot dynamically assign bind vars to the SCN in a flashback query, so we have to do row by row dynamic sql
		Our aim is to generate a unique list of business object masters, i.e. customer {rids, max(scn)}
		Get the max scn for each row id (we only need the last one in the time period)
		If it was a deletion we will see zero rows from these queries, so we have to look back one SCN to get the parent change logged
		Duplicates dont matter at this point, because we remove them in the next step

		for each target_tableN get the set {rid, max(scn) as target_scn}
			join back up to get the business object master
			insert into master_source_table
			select s1.rid, target_scn from customer s1, source_tableN n where s1.pk = n.fk at both scn, and scn-1
		end

		*/

		FOR m in c_metadata
		LOOP
			
			dbms_output.put_line(CHR(10) || 'Master: ' || m.master_table ||
			                                ' Level=' || m.child_level || 
											' L1=' || m.childL1_table || 
											' L2=' || m.childL2_table);

			CASE m.child_level
			WHEN 0 THEN
				tab := m.master_table;
			WHEN 1 THEN 
				tab := m.childL1_table;
			WHEN 2 THEN 
				tab := m.childL2_table;
			ELSE
				dbms_output.put_line('Unexpected metadata level!');
			END CASE;

			str := 'select optype, rid, max(scnno) scnno 
					from target.' || tab || ' 
			        where SCNNO between :start_scn and :end_scn 
					group by rid, optype 
					order by scnno';

			OPEN r FOR str using start_scn, end_scn;
			LOOP
				FETCH r INTO l_optype, l_rid, l_scnno;
				EXIT WHEN r%NOTFOUND;

				str1 := '';
				-- get_master_insert_hdr(c_master_table, str1);

				CASE m.child_level
				WHEN 0 THEN
					get_master_select1(
						optype => l_optype,
						master_table=> m.master_table,
						master_pk_col => m.master_pk,
						rid => l_rid, 
						scnno => l_scnno, 
						outSqlString => tmp);
				WHEN 1 THEN 
					get_master_select2(
						optype => 'C', 
						master_table=> m.master_table,
						master_pk_col => m.master_pk,
						childL1_table => m.childL1_table,
						childL1_fk_col => m.childL1_fk_col,
						rid => l_rid, 
						scnno => l_scnno, 
						outSqlString => tmp);
				WHEN 2 THEN 
					get_master_select3(
						optype => 'C', 
						master_table=> m.master_table,
						master_pk_col => m.master_pk,
						childL1_table => m.childL1_table,
						childL1_pk_col => m.childL1_pk_col,
						childL1_fk_col => m.childL1_fk_col,
						childL2_table => m.childL2_table,
						childL2_fk_col => m.childL2_fk_col,
						rid => l_rid, 
						scnno => l_scnno, 
						outSqlString => tmp);

				ELSE
					dbms_output.put_line('Unexpected metadata level!');
				END CASE;

				str2 := str1 || CHR(10) || tmp;
				dbms_output.put_line(str2 || ' using ' || to_char(l_scnno) || ', ' || l_rid);

				/*
					https://stewashton.wordpress.com/2018/07/23/optimistic-locking-8-double-checking-with-flashback/
					The EXECUTE privilege must be granted on DBMS_FLASHBACK;	
					The SCN parameter of ENABLE_AT_SYSTEM_CHANGE_NUMBER must be increasing!
						.... If it decreases, we get hard parses and extra child cursors.
					ORA-01466: unable to read data - table definition has changed
						.... caused partition splitting, so separate insert from select
				*/
			    sys.dbms_flashback.enable_at_system_change_number(l_scnno);
				execute immediate str2 into rec using l_scnno, l_rid;
			    sys.dbms_flashback.disable;

				get_master_insert(c_master_table, str2);
				dbms_output.put_line(str2);
				execute immediate str2 using rec.optype, rec.rid, rec.scnno;
				
				-- Must commit to avoid ORA-08183: Flashback cannot be enabled in the middle of a transaction
				commit; 

			END LOOP;
			CLOSE r;
		END LOOP;
		commit;

	end gen_master_data;

	procedure get_master_json_hdr_begin (master_table varchar2, l_optype char, outSqlString OUT varchar2) 
	IS
	begin
		outSqlString := '
			select json_object( 
					KEY ''optype'' VALUE ''' || l_optype || ''', 
					KEY ''customer'' VALUE JSON_OBJECT (m.*) ';	-- Note trailing "," is excluded
	end get_master_json_hdr_begin;

	procedure get_master_json_hdr_end (
							master_table IN varchar2, 
							scnno IN number, 
							rid IN ROWID, 
							outSqlString OUT varchar2) 
	IS
	begin
		outSqlString := '
							)
				from source.' || master_table || '@source_link m
				where m.rowid = :rid';
	end get_master_json_hdr_end;

	procedure get_child_json_query_L1 (
							child_table IN varchar2, 
							child_fk in varchar2,
							scnno IN number, 
							rid IN ROWID, 
							outSqlString OUT varchar2) 
	IS
	begin
		outSqlString := '
					,KEY ''' || child_table || ''' VALUE (
						SELECT JSON_ARRAYAGG (json_object(*))
						from source.' || child_table || '@source_link 
						where m.id = ' || child_table || '.' || child_fk || '
					)'; -- Note trailing "," is excluded
	end get_child_json_query_L1;

	procedure get_child_json_query_L2 (
							child_table_l1 IN varchar2, 
							child_l1_pk in varchar2,
							child_l1_fk in varchar2,
							child_table_l2 IN varchar2, 
							child_l2_fk in varchar2,
							scnno IN number, 
							rid IN ROWID, 
							outSqlString OUT varchar2) 
	IS
	begin
		outSqlString := '
					,KEY ''' || child_table_l2 || ''' VALUE (
						SELECT JSON_ARRAYAGG (json_object(l2.*))
						from source.' || child_table_l1 || '@source_link l1,
						     source.' || child_table_l2 || '@source_link l2 
						where m.id = l1.' || child_l1_fk || '
						and   l1.' || child_l1_pk || ' = l2.' || child_l2_fk || '
					)'; -- Note trailing "," is excluded
	end get_child_json_query_L2;


	procedure gen_master_data_json (start_scn number, end_scn number)
	is
		-- process each master table in order, then process by child level
		-- NOTE: we rely on this order below.

		cursor c_master is 
			select master_table from TARGET.SCHEMA_METADATA where child_level = 0;

		cursor c_metadata (l_master_table varchar2) is 
				select * 
				from TARGET.SCHEMA_METADATA 
				where master_table = l_master_table 
				order by master_table, child_level;

	    r SYS_REFCURSOR;

		str varchar2(2000);
		str1 varchar2(2000);
		str2 varchar2(2000);
		tmp varchar2(2000);
		l_rid ROWID;
		l_max_scnno number;
		l_json varchar2(32000);
		cnt number;

		tab varchar2(100);
		mastertab varchar2(100);

		l_optype varchar(100);

	begin

		dbms_output.put_line(CHR(10) || 'Processing: begin_scn=' || start_scn || ', end_scn=' || end_scn || ':');

		FOR m1 in c_master
		LOOP 

			mastertab := 'MASTER_' || m1.master_table;

			str := 'select /*+ opt_param(''cursor_sharing=force'') */ rid, max(scnno) scnno 
			from target.master_' || m1.master_table || ' 
			where SCNNO between ' || start_scn || ' and ' || end_scn || ' 
			group by rid order by 2';

			-- dbms_output.put_line(str);

			OPEN r FOR str;
			LOOP

				FETCH r INTO l_rid, l_max_scnno;
				EXIT WHEN r%NOTFOUND;
				dbms_output.put_line(CHR(10) || 'Processing: rid=' || l_rid || ' for max_scnno=' || l_max_scnno);

				cnt := 0;
				FOR m2 in c_metadata (m1.master_table)
				LOOP
					
					-- dbms_output.put_line(CHR(10) || 'Master: ' || m2.master_table ||
					-- 								' Level=' || m2.child_level || 
					-- 								' L1=' || m2.childL1_table || 
					-- 								' L2=' || m2.childL2_table);

					CASE m2.child_level
					WHEN 0 THEN

						-- Need to simplify optype = {D, I, or U}, as we will either delete or upsert in target
						tmp := 'select /*+ opt_param(''cursor_sharing=force'') */ 1 
								from target.' || mastertab || ' 
								where rid=''' || l_rid || ''' 
								and scnno=' || l_max_scnno || '
								and optype = ''D''';
						begin
							execute immediate tmp INTO l_optype;
						exception
							when NO_DATA_FOUND then	
								-- otherwise we want an UPSERT (change)
								l_optype := 'C';
						end;

						-- dbms_output.put_line(tmp);
						-- dbms_output.put_line('optype=' || l_optype);

						str1 := '';
						get_master_json_hdr_begin(m1.master_table, l_optype, str1);

					WHEN 1 THEN 
						str2 := '';
						get_child_json_query_l1 (m2.childL1_table, m2.childL1_fk_col, l_max_scnno, l_rid, str2);
						str1 := str1 || str2;

					WHEN 2 THEN 
						str2 := '';
						get_child_json_query_l2 (
									m2.childL1_table, 
									m2.childL1_pk_col, 
									m2.childL1_fk_col, 
									m2.childL2_table, 
									m2.childL2_fk_col, 
									l_max_scnno, l_rid, str2);
						str1 := str1 || str2;

					ELSE
						dbms_output.put_line('Unexpected metadata level!');
					END CASE;

					cnt := cnt + 1;

				END LOOP;

				get_master_json_hdr_end(m1.master_table, l_max_scnno, l_rid, str2);
				str1 := str1 || str2;
				dbms_output.put_line(str1);
				commit;
			    sys.dbms_flashback.enable_at_system_change_number(l_max_scnno);
				execute immediate str1 into l_json using l_rid;
				sys.dbms_flashback.disable;
				dbms_output.put_line(CHR(10));
				dbms_output.put_line(l_json);


			END LOOP;
			CLOSE r;

		END LOOP;
				
	end gen_master_data_json;


end poc_pkg;
/
show errors


/*
 sample generated code
			str := '
				select json_object(
					KEY ''customer'' VALUE JSON_OBJECT (s1.*),
					KEY ''customer_order'' VALUE (
						SELECT JSON_ARRAYAGG (json_object(s2.*))
						from source.customer_order@source_link as of scn ' || r.scnno || ' s2 
						where s1.id = s2.customer_id
					),
					KEY ''source_table3'' VALUE (
						SELECT JSON_ARRAYAGG (json_object(s3.*))
						from source.source_table3@source_link as of scn ' || r.scnno || ' s3 
						where s1.id = s3.customer_id
					)
				)
				from source.customer@source_link as of scn ' || r.scnno || ' s1
				where s1.rowid = ''' || r.rid || '''
			';
*/