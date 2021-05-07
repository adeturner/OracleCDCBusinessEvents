
set serveroutput on lines 2000 pages 1000 trimspool on feedback off
exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** testdata_e2e_test1.sql ***' );
exec dbms_output.put_line(CHR(10));

exec dbms_output.put_line( 'e2e_test1: reset test data' );
@testdata_reset

exec dbms_output.put_line( 'e2e_test1: insert 10 rows' );
@testdata_10rows_ins.sql

exec dbms_output.put_line( 'e2e_test1: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'e2e_test1: split partitions' );
@partition_split

exec dbms_output.put_line( 'e2e_test1: insert 10 rows' );
@testdata_10rows_ins.sql

exec dbms_output.put_line( 'e2e_test1: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'e2e_test1: split partitions' );
@partition_split

exec dbms_output.put_line( 'e2e_test1: update 10 rows' );
@testdata_10rows_upd.sql

exec dbms_output.put_line( 'e2e_test1: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'e2e_test1: delete 10 child rows' );
@testdata_10rows_del.sql

exec dbms_output.put_line( 'e2e_test1: wait for OGG to catchup...' );
exec sys.dbms_session.sleep(10);

exec dbms_output.put_line( 'e2e_test1: split partitions' );
@partition_split

exec dbms_output.put_line( 'e2e_test1: query the result' );
@source_query
@partition_query


-- testdata_e2e1

/*

TARGET_TABLE1.PART_0=0
TARGET_TABLE1.PART_2540814=10
TARGET_TABLE1.PART_2541208=10
TARGET_TABLE1.PART_2541389=10
TARGET_TABLE1.PART_2541622=0
TARGET_TABLE2.PART_0=0
TARGET_TABLE2.PART_2540814=10
TARGET_TABLE2.PART_2541208=10
TARGET_TABLE2.PART_2541389=20
TARGET_TABLE2.PART_2541622=0
TARGET_TABLE3.PART_0=0
TARGET_TABLE3.PART_2540814=10
TARGET_TABLE3.PART_2541208=10
TARGET_TABLE3.PART_2541389=20
TARGET_TABLE3.PART_2541622=0

*/



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

    cursor c_target (startscn number, endscn number) is
    select rid, max(scnno) scnno
    from target.target_table1 
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

        dbms_output.put_line(CHR(10) || 'Processing:' || cfg.partition_name || ' begin_scn=' || cfg.begin_scn || ', end_scn=' || cfg.end_scn || ':');

        -- For each rowid that is updated we want to get the max(scnno), and then look back to the source_table at that SCN
        -- It seems you cannot dynamically assign bind vars to the SCN in a flashback query, so we have to do row by row dynamic sql
        FOR r in c_target (cfg.begin_scn, cfg.end_scn) 
        LOOP

            str := 'select json_object(*) as json from source.source_table1 as of scn ' || r.scnno || ' t where rowid = ''' || r.rid || '''';

            OPEN c_source FOR str;
            LOOP

                FETCH c_source INTO json;
                EXIT WHEN c_source%notfound;
                dbms_output.put_line(json);

            END LOOP;
            CLOSE c_source;

        END LOOP;

    END LOOP;
end;
/

/*
Processing:PART_2540814 begin_scn=2540814, end_scn=2541207:
{"ID":2141,"NAME":"FcCZKgQcWYxBQnTvhbRZ","VERSION":1}
{"ID":2142,"NAME":"kLjWtzBJdActIJuMxqpY","VERSION":1}
{"ID":2143,"NAME":"FBmgRgyqCZQsvAyfOLrP","VERSION":1}
{"ID":2144,"NAME":"IXcxqzFhKOqQykLwoaZE","VERSION":1}
{"ID":2145,"NAME":"gGcrIzJljqEnTxHrRocr","VERSION":1}
{"ID":2146,"NAME":"rZEowDtMewviCMgkRGLX","VERSION":1}
{"ID":2147,"NAME":"LWwlpnwTrhZeITpQyVWQ","VERSION":1}
{"ID":2148,"NAME":"xPwsfAhyXbNhpoOlRHBy","VERSION":1}
{"ID":2149,"NAME":"SdkqJExKoLysTetafiYT","VERSION":1}
{"ID":2150,"NAME":"soxRtCdjFAfnOKVgcKsi","VERSION":1}

Processing:PART_2541208 begin_scn=2541208, end_scn=2541388:
{"ID":2151,"NAME":"KisUFCowZHcXguWbrKEm","VERSION":1}
{"ID":2152,"NAME":"SVpXksYEjHJUBMxsDocP","VERSION":1}
{"ID":2153,"NAME":"dvwuhOikuNWrrOaojQnj","VERSION":1}
{"ID":2154,"NAME":"QNxXavMJhVojQREcvmOS","VERSION":1}
{"ID":2155,"NAME":"TnrOPKIMJjtXahIajHuD","VERSION":1}
{"ID":2156,"NAME":"TgbnGYOZIKKfRAycbPYN","VERSION":1}
{"ID":2157,"NAME":"mwsQnhhzTTclnWdSntbC","VERSION":1}
{"ID":2158,"NAME":"DkVkgtisAtzJXAtFTFCJ","VERSION":1}
{"ID":2159,"NAME":"rWAPdPLuHdGlKIAdPAHY","VERSION":1}
{"ID":2160,"NAME":"sjIlOWigbmtFcfnkVVKY","VERSION":1}

Processing:PART_2541389 begin_scn=2541389, end_scn=2541621:
{"ID":2143,"NAME":"FBmgRgyqCZQsvAyfOLrP","VERSION":11}
*/