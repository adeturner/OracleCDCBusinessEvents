CREATE OR REPLACE PACKAGE target.perftest_pkg AS 

    procedure test_gen_data(
        n number,
        partition_name varchar2,
        begin_scn number,
        end_scn number
    );

    procedure test_gen_json(
        n number,
        begin_scn number,
        end_scn number
    );

END perftest_pkg; 
/
show errors

CREATE OR REPLACE PACKAGE BODY target.perftest_pkg AS 

    procedure test_gen_data(
        n number,
        partition_name varchar2,
        begin_scn number,
        end_scn number
    )
	is
	begin

        execute immediate 'alter session set sql_trace = true';

        for i in 1..n
        loop
            target.poc_pkg.gen_master_data(partition_name, begin_scn, end_scn);
        end loop;

        execute immediate 'alter session set sql_trace = false';

    end test_gen_data;

    procedure test_gen_json(
        n number,
        begin_scn number,
        end_scn number
    )
	is
	begin

        execute immediate 'alter session set sql_trace = true';

        for i in 1..n
        loop
            target.poc_pkg.gen_master_data_json(begin_scn, end_scn);
        end loop;

        execute immediate 'alter session set sql_trace = false';

    end test_gen_json;

end perftest_pkg;
/
show errors
