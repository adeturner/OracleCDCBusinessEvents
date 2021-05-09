set serveroutput on lines 2000 pages 1000 trimspool on feedback off

exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** gen_masterdata.sql ***' );
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
        target.poc_pkg.gen_master_data(cfg.partition_name, cfg.begin_scn, cfg.end_scn);
    END LOOP;
end;
/

exec dbms_output.put_line( 'INFO poc_e2e: query the result' );
@source_query
@partition_query
