# Testing the PoC

## Create new partition (split MAXVAL)

sqlplus system/password1@//localhost:1521/ORCLCDB @create_partition.sql

## generate more data

sqlplus system/password1@//localhost:1521/ORCLPDB1 @testdata_1000rows.sql

## check data has arrived

sqlplus system/password1@//localhost:1521/ORCLPDB1 @query_partition_counts.sql

## gather the unique business events

```code
select count(*) from target.target_table1@target_link partition (part_15);
select * from target.partition_config;
```

### PART_15 begin_scn=2334122 end_scn=2349797

```code
with t1 as (select * from target.target_table1 partition (part_15)),
     s1_begin as (select rowid, t.* from source.source_table1 as of scn 2334122 t),
     s1_end as (select rowid, t.* from source.source_table1 as of scn 2349797 t),
     s1_between as (select rowid, t.* from source.source_table1 versions between scn 2334122 and 2349797 t)
select 'BEGIN_AND_END', t1.* from t1 where exists (select 1 from s1_begin where rowid = t1.rid) and exists (select 1 from s1_end where rowid = t1.rid)
union 
select 'END_NOT_BEGIN', t1.* from t1 where exists (select 1 from s1_end where rowid = t1.rid) and not exists (select 1 from s1_begin where rowid = t1.rid)
union 
select 'END_NOT_BEGIN', t1.* from t1 where exists (select 1 from s1_end where rowid = t1.rid) and not exists (select 1 from s1_begin where rowid = t1.rid)
union
select 'BETWEEN_NOT_BEGIN_NOT_END', t1.* from t1 where exists (select 1 from s1_between where rowid = t1.rid) and not exists (select 1 from s1_end where rowid = t1.rid) and not exists (select 1 from s1_begin where rowid = t1.rid)
```
