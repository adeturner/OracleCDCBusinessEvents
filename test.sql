
declare
    cursor c1 is
        with t1 as (select * from target.target_table1 partition (:partname)),
            s1_begin as (select rowid, t.* from source.source_table1 as of scn :start_scn t),
            s1_end as (select rowid, t.* from source.source_table1 as of scn :end_scn t),
            s1_between as (select rowid, t.* from source.source_table1 versions between scn :start_scn and :end_scn t)
        select 'BEGIN_AND_END', t1.* from t1 
        where exists (select 1 from s1_begin where rowid = t1.rid) 
        and exists (select 1 from s1_end where rowid = t1.rid)
        union 
        select 'END_NOT_BEGIN', t1.* from t1 
        where exists (select 1 from s1_end where rowid = t1.rid) 
        and not exists (select 1 from s1_begin where rowid = t1.rid)
        union 
        select 'END_NOT_BEGIN', t1.* from t1
        where exists (select 1 from s1_end where rowid = t1.rid) 
        and not exists (select 1 from s1_begin where rowid = t1.rid)
        union
        select 'BETWEEN_NOT_BEGIN_NOT_END', t1.* from t1 
        where exists (select 1 from s1_between where rowid = t1.rid) 
        and not exists (select 1 from s1_end where rowid = t1.rid) 
        and not exists (select 1 from s1_begin where rowid = t1.rid);

    start_scn number;
    end_scn number;
    partname number;

begin

    FOR p IN c1
    LOOP

    END LOOP;

end;

end;
/