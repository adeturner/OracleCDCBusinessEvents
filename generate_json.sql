
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

        dbms_output.put_line(CHR(10) || 'Processing:' || cfg.partition_name || ' begin_scn=' || cfg.begin_scn || ', end_scn=' || cfg.end_scn || ':');

        -- For each rowid that is updated we want to get the max(scnno), and then look back to the source_table at that SCN
        -- It seems you cannot dynamically assign bind vars to the SCN in a flashback query, so we have to do row by row dynamic sql
        FOR r in c_target1 (cfg.begin_scn, cfg.end_scn) 
        LOOP

            str := '
                select json_object(
                    ''source_table1'' VALUE json_object(t1.*),
                    ''source_table2'' VALUE json_object(t2.*),
                    ''source_table3'' VALUE json_object(t3.*)) as json 
                from source.source_table1 as of scn ' || r.scnno || ' t1,
                     source.source_table2 as of scn ' || r.scnno || ' t2, 
                     source.source_table3 as of scn ' || r.scnno || ' t3 
                where t1.rowid = ''' || r.rid || '''
                and   t1.id = t2.source_table1_id (+)
                and   t1.id = t3.source_table1_id (+)
            ';

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
Processing:PART_2591988 begin_scn=2591988, end_scn=2592326:
{"source_table1":{"ID":2201,"NAME":"GruwFJBqjDDfbMbEkKWE","VERSION":1},"source_table2":{"ID":201,"SOURCE_TABLE1_ID":2201,"NAME":"RJDoqxIJlMHJqnMdwvvL","VERSION":1},"source_table3":{"ID":201,"SOURCE_TABLE1_ID":2201,"NAME":"RHveNiYCnVKDbWBwoCFq","VERSION":1}}
{"source_table1":{"ID":2202,"NAME":"VIzZrPIXIXPBSSjfrcqd","VERSION":1},"source_table2":{"ID":202,"SOURCE_TABLE1_ID":2202,"NAME":"SSNMjIFeqSTREvlIXEBV","VERSION":1},"source_table3":{"ID":202,"SOURCE_TABLE1_ID":2202,"NAME":"FoEFotjTyrZHVSDFRFEi","VERSION":1}}
{"source_table1":{"ID":2203,"NAME":"ibpMSBKpWkBxQuiHMwgi","VERSION":1},"source_table2":{"ID":203,"SOURCE_TABLE1_ID":2203,"NAME":"AfmMlWWVAqrFgqiYpOvL","VERSION":1},"source_table3":{"ID":203,"SOURCE_TABLE1_ID":2203,"NAME":"ekQPmIOhPjnRlrvTyMiT","VERSION":1}}
{"source_table1":{"ID":2204,"NAME":"rCvDbkVGJdSqgwxmoAuA","VERSION":1},"source_table2":{"ID":204,"SOURCE_TABLE1_ID":2204,"NAME":"FKnmhmZeCRrgRqOGUlVv","VERSION":1},"source_table3":{"ID":204,"SOURCE_TABLE1_ID":2204,"NAME":"mhYwglDZspUEWVFYpVie","VERSION":1}}
{"source_table1":{"ID":2205,"NAME":"BMmaUgwBiTiahSwmvrLZ","VERSION":1},"source_table2":{"ID":205,"SOURCE_TABLE1_ID":2205,"NAME":"ctjZnxFGMwkVyIWHOVxO","VERSION":1},"source_table3":{"ID":205,"SOURCE_TABLE1_ID":2205,"NAME":"EmAaHQqSMRyROREoKshh","VERSION":1}}
{"source_table1":{"ID":2206,"NAME":"dhXgcFivntAAdLzjKarA","VERSION":1},"source_table2":{"ID":206,"SOURCE_TABLE1_ID":2206,"NAME":"OEYaOoKIBEorCUvgriWv","VERSION":1},"source_table3":{"ID":206,"SOURCE_TABLE1_ID":2206,"NAME":"KqSqcyBYrvoYxFHsWhpd","VERSION":1}}
{"source_table1":{"ID":2207,"NAME":"JWnqOvhVtWfURKqrDZzG","VERSION":1},"source_table2":{"ID":207,"SOURCE_TABLE1_ID":2207,"NAME":"kzgyKwjZCkKBEJmYmALW","VERSION":1},"source_table3":{"ID":207,"SOURCE_TABLE1_ID":2207,"NAME":"UgtIGfPAfHyHhWbUSXQQ","VERSION":1}}
{"source_table1":{"ID":2208,"NAME":"frXyfRtDKCOYGtPrfwyq","VERSION":1},"source_table2":{"ID":208,"SOURCE_TABLE1_ID":2208,"NAME":"EihjGlWXhCpSrjVAymMR","VERSION":1},"source_table3":{"ID":208,"SOURCE_TABLE1_ID":2208,"NAME":"hdYmANyMSaKWFxAmctVN","VERSION":1}}
{"source_table1":{"ID":2209,"NAME":"TiWCljYEgbINZXcEvfwZ","VERSION":1},"source_table2":{"ID":209,"SOURCE_TABLE1_ID":2209,"NAME":"LhtmzpEUcrORViUTMxrg","VERSION":1},"source_table3":{"ID":209,"SOURCE_TABLE1_ID":2209,"NAME":"pHZsxnbAcwLoaPzTYbXO","VERSION":1}}
{"source_table1":{"ID":2210,"NAME":"amWBKcgmUTlkmWRIUVnc","VERSION":1},"source_table2":{"ID":210,"SOURCE_TABLE1_ID":2210,"NAME":"mQIDGNluJrinkNizjGeR","VERSION":1},"source_table3":{"ID":210,"SOURCE_TABLE1_ID":2210,"NAME":"GNlPScwuknwLrgRhAIwT","VERSION":1}}

Processing:PART_2592327 begin_scn=2592327, end_scn=2592512:
{"source_table1":{"ID":2211,"NAME":"UOaEhUjWcwZbiYsFtFyr","VERSION":1},"source_table2":{"ID":211,"SOURCE_TABLE1_ID":2211,"NAME":"BhFBXzUkVfSEVEVoiUmv","VERSION":1},"source_table3":{"ID":211,"SOURCE_TABLE1_ID":2211,"NAME":"YWVTLoQkmPYBqCUsOupD","VERSION":1}}
{"source_table1":{"ID":2212,"NAME":"ACbxBvPQtfAScUKNWWlK","VERSION":1},"source_table2":{"ID":212,"SOURCE_TABLE1_ID":2212,"NAME":"PtmLhnwjzLriXNtaSlkF","VERSION":1},"source_table3":{"ID":212,"SOURCE_TABLE1_ID":2212,"NAME":"TRDOjjOMYGCencPhqXhA","VERSION":1}}
{"source_table1":{"ID":2213,"NAME":"HGyQstsuFvSqopYzcBYG","VERSION":1},"source_table2":{"ID":213,"SOURCE_TABLE1_ID":2213,"NAME":"uzOnnGPNlaaZrjWMLvIp","VERSION":1},"source_table3":{"ID":213,"SOURCE_TABLE1_ID":2213,"NAME":"ehCMwbdQenokWvnuNOed","VERSION":1}}
{"source_table1":{"ID":2214,"NAME":"UTTxeoCzkhoHibTqarDR","VERSION":1},"source_table2":{"ID":214,"SOURCE_TABLE1_ID":2214,"NAME":"uDyHWOUExApfOcmJVFMg","VERSION":1},"source_table3":{"ID":214,"SOURCE_TABLE1_ID":2214,"NAME":"ISXNOHbwnqMHSclqhoBc","VERSION":1}}
{"source_table1":{"ID":2215,"NAME":"osfzKaQEgfXiJaeJLZEJ","VERSION":1},"source_table2":{"ID":215,"SOURCE_TABLE1_ID":2215,"NAME":"EgMQcbWvQolKxrgSsoRv","VERSION":1},"source_table3":{"ID":215,"SOURCE_TABLE1_ID":2215,"NAME":"myfwRrQdBpAmUOtRTBvb","VERSION":1}}
{"source_table1":{"ID":2216,"NAME":"OCPeWDBCPwExYjGWYcue","VERSION":1},"source_table2":{"ID":216,"SOURCE_TABLE1_ID":2216,"NAME":"RXhlCfbRtbtHrgZJCgzg","VERSION":1},"source_table3":{"ID":216,"SOURCE_TABLE1_ID":2216,"NAME":"nUbZZGItqnwlZdMRhqvQ","VERSION":1}}
{"source_table1":{"ID":2217,"NAME":"fvKGddGaQGDMxVEqdqfs","VERSION":1},"source_table2":{"ID":217,"SOURCE_TABLE1_ID":2217,"NAME":"SXCSEGZZXVZhbKnRyiAp","VERSION":1},"source_table3":{"ID":217,"SOURCE_TABLE1_ID":2217,"NAME":"MLFnIAbDTrKAOyijCjfA","VERSION":1}}
{"source_table1":{"ID":2218,"NAME":"zgHsQqdvDEgqBkgaYeVX","VERSION":1},"source_table2":{"ID":218,"SOURCE_TABLE1_ID":2218,"NAME":"yjZmUIQdtTRxOIhcCjjM","VERSION":1},"source_table3":{"ID":218,"SOURCE_TABLE1_ID":2218,"NAME":"FHtUcqbndEHATFnToYVJ","VERSION":1}}
{"source_table1":{"ID":2219,"NAME":"KvsRMNTEUPnemPsbaAax","VERSION":1},"source_table2":{"ID":219,"SOURCE_TABLE1_ID":2219,"NAME":"MYeMYFQDgDmMebdSVNZw","VERSION":1},"source_table3":{"ID":219,"SOURCE_TABLE1_ID":2219,"NAME":"GORPTzctFNQBwAWiAJUt","VERSION":1}}
{"source_table1":{"ID":2220,"NAME":"RGQyrQwIcRYgOrNgYHGe","VERSION":1},"source_table2":{"ID":220,"SOURCE_TABLE1_ID":2220,"NAME":"ShEdEJuflyMmTpvyfOYw","VERSION":1},"source_table3":{"ID":220,"SOURCE_TABLE1_ID":2220,"NAME":"RAaUFehVHcMTqZXVPLec","VERSION":1}}

Processing:PART_2592513 begin_scn=2592513, end_scn=2592703:
{"source_table1":{"ID":2203,"NAME":"ibpMSBKpWkBxQuiHMwgi","VERSION":6},"source_table2":{"ID":203,"SOURCE_TABLE1_ID":2203,"NAME":"AfmMlWWVAqrFgqiYpOvL","VERSION":1},"source_table3":{"ID":203,"SOURCE_TABLE1_ID":2203,"NAME":"ekQPmIOhPjnRlrvTyMiT","VERSION":1}}
*/
