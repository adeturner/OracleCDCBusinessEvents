
# Using Goldengate Change Data Capture to generate infrequent and whole business events

## Introduction

A common pattern is to integrate an on-prem oracle database with a modernised cloud environment to support, for example, a strangler pattern

Goldengate for Big Data generates record by record events that can be streamed to e.g. Kafka.  

But For some databases change data capture generates a large amount of change volume and requires scaling e.g. through multiple kafka consumers.

In these scenarios we are unlikely to maintain transactional consistency of business objects, as individual CDC records may not be processed in order.

**We demonstrate an eventually consistent method to generate a proportionately low volume of transactionally consistent business events from a high volume change data capture stream**

The following diagram details the process; note Source and Target can either be separate or the same database.

![Overview](/Overview.JPG "Overview of approach")

We present two POCs

- POC #1 (obsolete) complete, but mothballed as I wasn't happy with it (fail fast)

- POC #2 is functionally complete, but requires additional functional testing, further development to productionise.  

The POC2 high level summary: 

- Uses an example complex multi-level schema
- Metadata driven (extent can easily be improved)
- Changes are reported against the CUSTOMER master table, even if the update occured on a detail table up to two levels below (CUSTOMER_ORDERS, ORDER_DETAIL, ADDRESS or DELIVER) (can increase complexity easily)
- Multiple updates against the same CUSTOMER during a period are aggregated, and the CUSTOMER object is only transmitted once.
- The POC readme shows the JSON that is produced to stdout: https://github.com/adeturner/OracleCDCBusinessEvents/tree/main/POC2
- The JSON can be sent to an AQ queue, API etc directly from PLSQL (not shown)

POC2 to do list:

- alter session set cursor_sharing=FORCE (fix for SCNs in dynamic sql, added in poc_e2e.sql now)
- statistics strategy
- diagram for README
- JSON generation fix for optype="D" (currently suboptimal)

## Setup

1. Follow 1_dockerSetup.md

2. Follow 2_oggSetup.md

3. Follow the README in the appropriate POC directory

## Key files

Both POCs use the same structure:

- README

- sql/*.sql are supporting files that work for both POCs

- ogg/*.sh are supporting files that work for both POCs

In each POC directory the key files of note are:

- env.sh is a pre-req for the POC and configures the environment

- schema_ddl.sql

- poc_pkg.sql is the core of the code

- poc_e2e.sql runs the end to end proof of concept

- poc_cleanup.sql tidies up

- a .lst file - the output of the last execution of the POC