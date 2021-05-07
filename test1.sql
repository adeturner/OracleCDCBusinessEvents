
@partition_query

declare
    cursor c1 (partname varchar2, start_scn number, end_scn number) is
        --
        -- let oracle work out the partition to scan from the partition key
        with t1 as (select * from target.target_table1 where SCNNO between start_scn and end_scn),
            s1_begin as (select rowid, t.* from source.source_table1 as of scn start_scn t),
            s1_end as (select rowid, t.* from source.source_table1 as of scn end_scn t),
            s1_between as (select rowid, t.* from source.source_table1 versions between scn start_scn and end_scn t)
        --
        select 'BEGIN_AND_END' rowtype, t1.rid, t1.optype from t1         
        where exists (select 1 from s1_begin where rowid = t1.rid) 
        and exists (select 1 from s1_end where rowid = t1.rid)
        union 
        --
        select 'END_NOT_BEGIN', t1.rid, t1.optype from t1 
        where exists (select 1 from s1_end where rowid = t1.rid) 
        and not exists (select 1 from s1_begin where rowid = t1.rid)
        union 
        --
        select 'END_NOT_BEGIN', t1.rid, t1.optype from t1
        where exists (select 1 from s1_end where rowid = t1.rid) 
        and not exists (select 1 from s1_begin where rowid = t1.rid)
        union
        --
        select 'BETWEEN_NOT_BEGIN_NOT_END', t1.rid, t1.optype from t1 
        where exists (select 1 from s1_between where rowid = t1.rid) 
        and not exists (select 1 from s1_end where rowid = t1.rid) 
        and not exists (select 1 from s1_begin where rowid = t1.rid);

    cursor c2 is 
        select * 
        from target.partition_config 
        where module_name = 'POC'
        and partition_name != 'PART_0'
        and end_scn is not null
        order by begin_scn;

    rec c1%rowtype;

begin

    FOR cfg IN c2
    LOOP

        dbms_output.put_line('Processing:' || cfg.partition_name);
        OPEN c1(cfg.partition_name, cfg.begin_scn, cfg.end_scn);
        LOOP
            FETCH c1 INTO rec;
            EXIT WHEN c1%notfound;
            dbms_output.put_line(rec.rowtype || ',' || rec.rid || ',' || rec.optype);
        END LOOP;
        CLOSE c1;

    END LOOP;

end;
/