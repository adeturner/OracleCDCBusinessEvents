
@partition_query

set serveroutput on lines 1000 pages 1000 trimspool on

CREATE OR REPLACE TYPE target.s1_type AS OBJECT ( 
   id          number,
   name        varchar2(200),
   version     number);
/
show errors

declare

    TYPE cursort  IS REF CURSOR;
    c1 cursort;
    rec target.s1_type;

    cursor c2 is 
        select * 
        from target.partition_config 
        where module_name = 'POC'
        and partition_name != 'PART_0'
        and end_scn is not null
        order by begin_scn;

    scnRange varchar2(2000);
    str varchar2(2000);

begin

    FOR cfg IN c2
    LOOP
        dbms_output.put_line('Processing:' || cfg.partition_name || ' begin_scn=' || cfg.begin_scn || ', end_scn=' || cfg.end_scn);

        scnRange := to_char(cfg.begin_scn) || ' and ' || to_char(cfg.end_scn);

        str := '
        with 
        t1 as (select * from target.target_table1 where SCNNO between ' || scnRange || '),
        s1_between as (select rowid, t.* from source.source_table1 versions between scn ' || scnRange || ' t)
        select id, name, version from s1_between where exists (select 1 from t1 where rowid = t1.rid)
        ';

        dbms_output.put_line(str);

        OPEN c1 FOR str;
        LOOP
            FETCH c1 INTO rec;
            EXIT WHEN c1%notfound;
            dbms_output.put_line(rec.id || ',' || rec.name || ',' || rec.version);
        END LOOP;
        CLOSE c1;

    END LOOP;

end;
/



/*
        with 
            t1 as (select * from target.target_table1 where SCNNO between 2540814 and 2541207),
            s1_between as (select rowid, t.* from source.source_table1 versions between scn 2540814 and 2541207 t)
        select 's1.BETWEEN' rowtype, id, name, version from s1_between s where exists (select 1 from t1 where s.rowid = t1.rid);


        with 
            t1 as (select * from target.target_table1 where SCNNO between start_scn and end_scn),
            t2 as (select * from target.target_table2 where SCNNO between start_scn and end_scn),
            t3 as (select * from target.target_table3 where SCNNO between start_scn and end_scn),
            s1_begin as (select rowid, t.* from source.source_table1 as of scn start_scn t),
            s1_end as (select rowid, t.* from source.source_table1 as of scn end_scn t),
            s1_between as (select rowid, t.* from source.source_table1 versions between scn start_scn and end_scn t),
            s2_begin as (select rowid, t.* from source.source_table2 as of scn start_scn t),
            s2_end as (select rowid, t.* from source.source_table2 as of scn end_scn t),
            s2_between as (select rowid, t.* from source.source_table2 versions between scn start_scn and end_scn t),
            s3_begin as (select rowid, t.* from source.source_table3 as of scn start_scn t),
            s3_end as (select rowid, t.* from source.source_table3 as of scn end_scn t),
            s3_between as (select rowid, t.* from source.source_table3 versions between scn start_scn and end_scn t)
        select 's1.BEGIN' rowtype, id, name, version from s1_begin where exists (select 1 from t1 where rowid = t1.rid) union
        select 's1.END' rowtype, id, name, version from s1_end where exists (select 1 from t1 where rowid = t1.rid) union
        select 's1.BETWEEN' rowtype, id, name, version from s1_between where exists (select 1 from t1 where rowid = t1.rid) union
        select 's2.BEGIN' rowtype, id, name, version from s2_begin where exists (select 1 from t2 where rowid = t2.rid) union
        select 's2.END' rowtype, id, name, version from s2_end where exists (select 1 from t2 where rowid = t2.rid) union
        select 's2.BETWEEN' rowtype, id, name, version from s2_between where exists (select 1 from t2 where rowid = t2.rid) union
        select 's3.BEGIN' rowtype, id, name, version from s3_begin where exists (select 1 from t3 where rowid = t3.rid) union
        select 's3.END' rowtype, id, name, version from s3_end where exists (select 1 from t3 where rowid = t3.rid) union
        select 's3.BETWEEN' rowtype, id, name, version from s3_between where exists (select 1 from t3 where rowid = t3.rid);


select * from target.target_table1 where SCNNO between 2540814 and 2541207
        
PK            MODIFY_TIME                                                                 RID                     SCNNO O
------------- --------------------------------------------------------------------------- ------------------ ---------- -
2141          07-MAY-21 09.39.14.000000 AM                                                AAAR1KAAMAAAACTAAS    2541136 I
2142          07-MAY-21 09.39.14.000000 AM                                                AAAR1KAAMAAAACTAAT    2541139 I
2143          07-MAY-21 09.39.14.000000 AM                                                AAAR1KAAMAAAACTAAA    2541142 I
2144          07-MAY-21 09.39.14.000000 AM                                                AAAR1KAAMAAAACTAAB    2541145 I
2145          07-MAY-21 09.39.14.000000 AM                                                AAAR1KAAMAAAACTAAC    2541148 I
2146          07-MAY-21 09.39.14.000000 AM                                                AAAR1KAAMAAAACTAAD    2541151 I
2147          07-MAY-21 09.39.14.000000 AM                                                AAAR1KAAMAAAACTAAE    2541154 I
2148          07-MAY-21 09.39.14.000000 AM                                                AAAR1KAAMAAAACTAAF    2541157 I
2149          07-MAY-21 09.39.14.000000 AM                                                AAAR1KAAMAAAACTAAG    2541160 I
2150          07-MAY-21 09.39.14.000000 AM                                                AAAR1KAAMAAAACTAAH    2541163 I

        with 
            t1 as (select * from target.target_table1 where SCNNO between 2540814 and 2541207),
            s1_between as (select rowid, t.* from source.source_table1 versions between scn 2540814 and 2541207 t)
        select 's1.BETWEEN' rowtype, id, name, version from s1_between s where exists (select 1 from t1 where s.rowid = t1.rid);



        with 
            t1 as (select * from target.target_table1 where SCNNO between 2540814 and 2541207),
            s1_begin as (select rowid, t.* from source.source_table1 as of scn 2540814 t 
                         where not exists (select 1 from source.source_table1 x as of scn 2541207 where x.rowid = t.rowid)),
            s1_end as (select rowid, t.* from source.source_table1 as of scn 2541207 t
                       where not exists (select 1 from source.source_table1 x as of scn 2540814 where x.rowid = t.rowid)),
            s1_between as (select rowid, t.* from source.source_table1 versions between scn 2540814 and 2541207 t)
        select 's1.BEGIN' rowtype, id, name, version from s1_begin s where exists (select 1 from t1 where s.rowid = t1.rid) union
        select 's1.END' rowtype, id, name, version from s1_end s where exists (select 1 from t1 where s.rowid = t1.rid) union
        select 's1.BETWEEN' rowtype, id, name, version from s1_between s where exists (select 1 from t1 where s.rowid = t1.rid);


        */
