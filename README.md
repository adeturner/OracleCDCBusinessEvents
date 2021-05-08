
# Using Goldengate Change Data Capture to generate infrequent and whole business events

A common pattern is to integrate an on-prem oracle database with a modernised cloud environment to support, for example, a strangler pattern

Goldengate for Big Data generates record by record events that can be streamed to e.g. Kafka.  But For some databases change data capture generates a large amount of change volume and scaling (e.g. through multiple kafka consumers) is likely to mean that we cannot respect transaction boundaries.

This repo demonstrates an eventually consistent method to use Goldengate to generate a limited volume of whole transactionally consistent business events.

## 1. Algorithm

### Background

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

There appears to be a constraint with flashback query that SCN must be hard coded at parse time which implies row by row processing is required; the algorithm offers optimisation to mitigate that.

### Algorithm

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

## Setup

- Follow 1_dockerSetup.md
- Follow 2_oggSetup.md
- Follow 3_pocSchemaSetup.md

### End to End test

Execute poc_e2e.sql

- Start OGG
- Simulate insert 10 rows, insert 10 rows, update 10 rows, delete 10 rows
- Split partitions
- (WIP) Create a business object from the data
