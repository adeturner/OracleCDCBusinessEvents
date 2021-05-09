
set serveroutput on lines 2000 pages 1000 trimspool on feedback off

exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** gen_masterdata_json.sql ***' );
exec dbms_output.put_line(CHR(10));

declare
    cursor c_cfg is 
        select * 
        from target.partition_config 
        where module_name = 'POC'
        and partition_name != 'PART_0'
        and end_scn is not null
        order by begin_scn;

begin
    -- for each partition in partition config
    FOR cfg IN c_cfg
    LOOP
        target.poc_pkg.gen_master_data_json(cfg.begin_scn, cfg.end_scn);
    END LOOP;
end;
/

/*

SHOWING HISTORICAL WORKINGS FOR REFERENCE:

select json_object(
    KEY 'source_table1' VALUE s1.*
)
from source.source_table1 as of scn 2994264 s1
where s1.rowid = 'AAAR1KAAMAAAACHAAK';

select json_object(
    KEY 'source_table1' VALUE (
        SELECT JSON_ARRAYAGG (JSON_OBJECT (s1.*))
        from source.source_table1 as of scn 2994264 s1
        where s1.rowid = 'AAAR1KAAMAAAACHAAK'
    )
)
from dual;

select json_object(
    KEY 'source_table1' VALUE JSON_OBJECT (s1.*),
    KEY 'source_table2' VALUE (
        SELECT JSON_ARRAYAGG (json_object(s2.*))
        from source.source_table2 as of scn 2994264 s2 
        where s1.id = s2.source_table1_id
    ),
    KEY 'source_table3' VALUE (
        SELECT JSON_ARRAYAGG (json_object(s3.*))
        from source.source_table3 as of scn 2994264 s3 
        where s1.id = s3.source_table1_id
    )
)
from source.source_table1 as of scn 2994264 s1
where s1.rowid = 'AAAR1KAAMAAAACHAAK';


declare
    cursor c_cfg is 
        select begin_scn, end_scn
        from target.partition_config 
        where module_name = 'POC'
        and partition_name != 'PART_0'
        and end_scn is not null
        order by begin_scn;

    cursor c_master (startscn number, endscn number) is
		select rid, max(scnno) scnno 
        from target.master_source_table1 
        where SCNNO between startscn and endscn 
        group by rid order by 2;
    str varchar2(2000);
    l_json varchar2(2000);
begin

    -- for each partition in partition config
    FOR cfg IN c_cfg
    LOOP
        dbms_output.put_line(CHR(10) || 'Processing: begin_scn=' || cfg.begin_scn || ', end_scn=' || cfg.end_scn || ':');

		FOR r in c_master (cfg.begin_scn, cfg.end_scn) 
		LOOP
            
            dbms_output.put_line(CHR(10) || 'Processing: rowid=' || r.rid || ' scnno=' || r.scnno);

            str := '
                select json_object(
                    KEY ''source_table1'' VALUE JSON_OBJECT (s1.*),
                    KEY ''source_table2'' VALUE (
                        SELECT JSON_ARRAYAGG (json_object(s2.*))
                        from source.source_table2 as of scn ' || r.scnno || ' s2 
                        where s1.id = s2.source_table1_id
                    ),
                    KEY ''source_table3'' VALUE (
                        SELECT JSON_ARRAYAGG (json_object(s3.*))
                        from source.source_table3 as of scn ' || r.scnno || ' s3 
                        where s1.id = s3.source_table1_id
                    )
                )
                from source.source_table1 as of scn ' || r.scnno || ' s1
                where s1.rowid = ''' || r.rid || '''
            ';

            execute immediate str into l_json;
            dbms_output.put_line(l_json);

		END LOOP;
		
    END LOOP;
end;
/


Useful: https://oracle-base.com/articles/12c/sql-json-functions-12cr2

*/
