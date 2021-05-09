# POC1

This README covers the following sections:

1. Background
2. Algorithm
3. PoC Setup
4. PoC Execution
5. PoC Cleanup

## 1. Background

We are solving for business objects that can be described by:

an identifying parent table 

    PARENT TABLE source_table1 s1 (s1.pk)

with any number of child tables linked by foreign keys:

... with immediate relatives

    CHILD TABLE  source_table2 s2 (s1.pk=s2.fk)
    CHILD TABLE  source_table3 s3 (s1.pk=s3.fk)

... and include nested, cascaded:

    CHILD TABLE  source_table4 s4 (s1.pk=s4.fk)
    CHILD TABLE  source_table5 s5 (s4.pk=s5.fk)
    CHILD TABLE  source_table6 s6 (s4.pk=s6.fk)

We use an eventually consistent approach, to minimise the number of records needed to be processed

We use OGG to capture the ROWID, SCN for each change.

We partition the OGG target tables by SCN range, and split on interval, e.g. 5, 10, N mins

This PoC presents the method for tables s1,s2,s3 above

NOTE: There appears to be a constraint with flashback query that SCN must be hard coded at parse time which implies row by row processing is required.

POC1 describes the original row by row approach to mitigate the flashback query. During writing it was felt that it was too intrusive on the source database, partly because of the flashback query problem.

Example POC1 output is shown below, with each business object comprising the master/parent table record supported by arrays of detail/child tables

```code
    {
        "source_table1": {
            "ID": 2540,
            "NAME": "reDfdpuRUiSBUJjnwZDr",
            "VERSION": 1
        },
        "source_table2": [{
            "ID": 540,
            "SOURCE_TABLE1_ID": 2540,
            "NAME": "tbosRMEfJuqTIWqbqMiT",
            "VERSION": 1
        }],
        "source_table3": [{
            "ID": 540,
            "SOURCE_TABLE1_ID": 2540,
            "NAME": "koOtWZEeMyjmpheIqHLn",
            "VERSION": 1
        }]
    }
```

It is a short step from here to put each record on an AQ, or to an API using UTL_HTTP

## 2. Algorithm

```code

// Through OGG we have tracked the changes at each table level within the business object
// these are stored in TARGET.TARGET_TABLEn

for each partition in partition config

    // Our next aim is to generate a unique list of object masters, i.e. source_table1 {rid, max(scn)}

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
```

## 3. PoC Setup

### Create schema owners

```code
sqlplus system/password1@//localhost:1521/ORCLCDB @schema_create.sql
```

### tables

```code
sqlplus system/password1@//localhost:1521/ORCLCDB @schema_ddl.sql
```

### manager parameters

Copy mgr.prm to /opt/oracle/product/ogg19/dirprm/mgr.prm

### capture parameters

Copy extr1.prm to /opt/oracle/product/ogg19/dirprm/extr1.prm

### apply parameters

Copy repl1.prm to /opt/oracle/product/ogg19/dirprm/repl1.prm

### start ogg

```code
ogg/ogg_setup.sh

ogg/ogg_start.sh

# check they start
ogg/ogg_info.sh
ogg/ogg_report.sh
```

### insert test data and check ogg is working

```code
sqlplus system/password1@//localhost:1521/ORCLPDB1 @testdata_1000rows.sql

# expected result: 1000

select count(*) from target.target_table1;
```

## 4. PoC Execution

```code
sqlplus system/password1@//localhost:1521/ORCLPDB1 @poc_e2e.sql
```

## 5. PoC Cleanup

```code
sqlplus system/password1@//localhost:1521/ORCLPDB1 @poc_cleanup.sql
```