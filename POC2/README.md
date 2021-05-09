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

    PARENT TABLE CUSTOMER

with any number of child tables linked by foreign keys:

... with immediate relatives

    CHILD TABLE  CUSTOMER_ORDER
    CHILD TABLE  ADDRESS 

... and include nested, cascaded:

    CHILD TABLE  ORDER_DETAIL (child of order)
    CHILD TABLE  DELIVERY (child of address, order)

We use an eventually consistent approach, to minimise the number of records needed to be processed

We use OGG to capture the ROWID, SCN for each change.

We partition the OGG target tables by SCN range, and split on interval, e.g. 5, 10, N mins

This PoC presents the method for CUSTOMER mastered tables above using a METADATA table containing the relations between the tables.

NOTE: There appears to be a constraint with flashback query that SCN must be hard coded at parse time which implies row by row processing is required.

POC2 enhances POC1, bringing a step towards metadata driven code.  POC2 continues to use original row by row approach to mitigate the flashback query, which still calls back to the source database. Currently the only way to mitigate impact on Source would be to fully replicate the source tables to the remote location.

Example POC2 output is shown below, with each business object comprising the master/parent table record supported by arrays of detail/child tables

```code
select json_object(
                KEY 'optype' VALUE 'C',
                KEY 'customer' VALUE JSON_OBJECT (m.*) 
                ,KEY 'CUSTOMER_ORDER' VALUE (
                        SELECT JSON_ARRAYAGG (json_object(*))
                        from source.CUSTOMER_ORDER@source_link as of scn 3113228
                        where m.id = CUSTOMER_ORDER.CUSTOMER_ID
                )
                ,KEY 'ADDRESS' VALUE (
                        SELECT JSON_ARRAYAGG (json_object(*))
                        from source.ADDRESS@source_link as of scn 3113228
                        where m.id = ADDRESS.CUSTOMER_ID
                )
                ,KEY 'ORDER_DETAIL' VALUE (
                        SELECT JSON_ARRAYAGG (json_object(l2.*))
                        from source.CUSTOMER_ORDER@source_link as of scn 3113228 l1,
                                source.ORDER_DETAIL@source_link as of scn 3113228 l2
                        where m.id = l1.CUSTOMER_ID
                        and   l1.ID = l2.ORDER_ID
                )
                ,KEY 'DELIVERY' VALUE (
                        SELECT JSON_ARRAYAGG (json_object(l2.*))
                        from source.ADDRESS@source_link as of scn 3113228 l1,
                                source.DELIVERY@source_link as of scn 3113228 l2
                        where m.id = l1.CUSTOMER_ID
                        and   l1.ID = l2.ADDRESS_ID
                )
                                )
        from source.CUSTOMER@source_link as of scn 3113228 m
        where m.rowid = 'AAASMSAAMAAAACUAAC'

-- FORMATTED FOR EASE OF READING:
{
"optype":"C",

"customer":{"ID":4,"NAME":"pPIfjwSUWNkiiQmjXSfU","VERSION":1},

"CUSTOMER_ORDER":[{"ID":13,"CUSTOMER_ID":4,"NAME":"JxRngySFyWQruAfQCCDA","VERSION":1},{"ID":14,"CUSTOMER_ID":4,"NAME":"WrKZRXdWHJGVccDwuXKN","VERSION":1},{"ID":15,"CUSTOMER_ID":4,"NAME":"QGnIsscVvyXBOfLPSJAU","VERSION":1},{"ID":16,"CUSTOMER_ID":4,"NAME":"MffKLBqDxGnHLhxJIlXd","VERSION":1}],

"ADDRESS":[{"ID":7,"CUSTOMER_ID":4,"ADDRESS":"abHXantYRGkNRzKKhNQS","VERSION":1},{"ID":8,"CUSTOMER_ID":4,"ADDRESS":"oSzkkXzfJCClkguCQOIf","VERSION":1}],

"ORDER_DETAIL":[{"ID":61,"ORDER_ID":13,"DETAIL":"CDioNvtQeCBhPxIGZacY","VERSION":1},{"ID":62,"ORDER_ID":13,"DETAIL":"JKPMGQdUCOLkQzGXsLEK","VERSION":1},{"ID":63,"ORDER_ID":13,"DETAIL":"BUmNTZxUbIpMMSNJTMIP","VERSION":1},{"ID":64,"ORDER_ID":13,"DETAIL":"JFBvBHEIIMRauPmdjNhh","VERSION":1},{"ID":65,"ORDER_ID":13,"DETAIL":"RhJLWWLSgHPOuEFrSqgF","VERSION":1},{"ID":78,"ORDER_ID":16,"DETAIL":"whTLcfDIIKlaSgpZxJLK","VERSION":1},{"ID":79,"ORDER_ID":16,"DETAIL":"valoAwGgMYBtIfnuNMTf","VERSION":1},{"ID":80,"ORDER_ID":16,"DETAIL":"gxszoEorORBNQRtweZro","VERSION":1}],

"DELIVERY":[{"ID":13,"ORDER_ID":13,"ADDRESS_ID":7,"NAME":"lPvVYcqvfursfpdqevfN","VERSION":1},{"ID":14,"ORDER_ID":14,"ADDRESS_ID":7,"NAME":"fuKUKzHaQrQYiXzSVixT","VERSION":1},{"ID":15,"ORDER_ID":15,"ADDRESS_ID":8,"NAME":"kvkIfLuBzoYCKujlLTGM","VERSION":1},{"ID":16,"ORDER_ID":16,"ADDRESS_ID":8,"NAME":"EEBRqZUgtIEeHDJjeZgO","VERSION":1}]
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

### a. create schema owners

```code
sqlplus system/password1@//localhost:1521/ORCLCDB @schema_create.sql
```

### b. create tables

```code
sqlplus system/password1@//localhost:1521/ORCLCDB @schema_ddl.sql
```

### c. configure ogg parameters

..\ogg\ogg_copy_params.sh

### d. start ogg

```code
ogg/ogg_setup.sh

ogg/ogg_start.sh

# check they start
ogg/ogg_info.sh
ogg/ogg_report.sh
```

## 4. PoC Execution

```code
sqlplus system/password1@//localhost:1521/ORCLPDB1 @poc_e2e.sql
```

## 5. PoC Cleanup

```code
sqlplus system/password1@//localhost:1521/ORCLPDB1 @poc_cleanup.sql
```
