
set serveroutput on lines 2000 pages 1000 trimspool on feedback off

exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** generate_data.sql ***' );
exec dbms_output.put_line(CHR(10));

declare

    TYPE ctype  IS REF CURSOR;
    c_source ctype;

    cursor c_cfg is 
        select * 
        from target.partition_config 
        where module_name = 'POC'
        and partition_name != 'PART_0'
        and end_scn is not null
        order by begin_scn;

    cursor c_target1 (startscn number, endscn number) is
    select rid, max(scnno) scnno
    from target.target_table1 
    where SCNNO between startscn and endscn
    group by rid 
    order by 2;

    cursor c_target2 (startscn number, endscn number) is
    select rid, max(scnno) scnno
    from target.target_table2 
    where SCNNO between startscn and endscn
    group by rid 
    order by 2;

    cursor c_target3 (startscn number, endscn number) is
    select rid, max(scnno) scnno
    from target.target_table3 
    where SCNNO between startscn and endscn
    group by rid 
    order by 2;


    str varchar2(2000);
    json varchar2(2000);

    id          number;
    name        varchar2(200);
    version     number;

begin

    FOR cfg IN c_cfg
    LOOP

        execute immediate ('alter table target.COPY_SOURCE_TABLE1 truncate partition ' || cfg.partition_name);
        execute immediate ('alter table target.COPY_SOURCE_TABLE2 truncate partition ' || cfg.partition_name);
        execute immediate ('alter table target.COPY_SOURCE_TABLE3 truncate partition ' || cfg.partition_name);

        dbms_output.put_line(CHR(10) || 'Processing:' || cfg.partition_name || ' begin_scn=' || cfg.begin_scn || ', end_scn=' || cfg.end_scn || ':');

        -- For each rowid that is updated we want to get the max(scnno), and then look back to the source_table at that SCN
        -- It seems you cannot dynamically assign bind vars to the SCN in a flashback query, so we have to do row by row dynamic sql


        /*
            Algorithm:
            
            for each partition in partition config

                // Through OGG we have tracked the changes at each table level within the business object

                // Our next aim is tp generate a unique list of business object masters, i.e. source_table1 {rids, max(scn)}

                // get the max scn for each row id (we only need the last one in the time period)
                for each target_tableN get the set {rid, max(scn) as target_scn}

                    // join back up to get the business object master
                    insert into master_source_table
                    select s1.rid, target_scn from source_table1 s1, source_tableN n wherre s1.pk = n.fk

                end

                // in master_source_table we now have the full set of changes at business object layer
                // we only need to generate the object for the last one

                // loop through the max scn for each business object
                select rid, max(scn) as max_scn from master_source_table
                loop 
                    select <business object> 
                    from source_table1 s1 as of max_scn, 
                    source_table1 s2 as of max_scn, 
                    .. 
                    source_table1 sN as of max_scn
                    where s1.rowid = rid
                    and   s1.pk = s2.fk
                    ...
                    and   s1.pk = sN.fk
                    and   s1.row
                end

            end
        */


        FOR r in c_target1 (cfg.begin_scn, cfg.end_scn) 
        LOOP

            str := '
                insert into target.copy_source_table1
                select * from source.source_table1 as of scn ' || r.scnno || ' t1,
                where t1.rowid = ''' || r.rid || '''
            ';

			dbms_output.put_line(str);

        END LOOP;

        FOR r in c_target2 (cfg.begin_scn, cfg.end_scn) 
        LOOP

            str := '
                insert into target.copy_source_table1
                select * from source.source_table1 as of scn ' || r.scnno || ' t1,
                where t1.rowid = ''' || r.rid || '''
            ';

			dbms_output.put_line(str);

        END LOOP;

    END LOOP;
end;
/

exec dbms_output.put_line( 'INFO poc_e2e: query the result' );
@source_query
@partition_query
