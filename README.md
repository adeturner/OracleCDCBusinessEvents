
# Using Goldengate Change Data Capture to generate infrequent and whole business events

A common pattern is to integrate an on-prem oracle database with a modernised cloud environment to support, for example, a strangler pattern

Goldengate for Big Data generates record by record events that can be streamed to e.g. Kafka.  But For some databases change data capture generates a large amount of change volume and scaling (e.g. through multiple kafka consumers) is likely to mean that we cannot respect transaction boundaries.

This repo demonstrates an eventually consistent method to use Goldengate to generate a limited volume of whole transactionally consistent business events.

## 1. Setup database environment

Follow 1_dockerSetup.md

## 2. Setup ogg environment

Follow 2_oggSetup.md

## 3. Setup PoC environment

Follow 3_pocSchemaSetup.md

## 4. Test the PoC

### 4.1 testdata_e2e1

Simulate insert 10 rows, insert 10 rows, update 10 rows, delete 10 rows

(WIP) Create a business object from the data, resulting in expected output like the below:

```code
@testdata_e2e1

Processing:PART_2591988 begin_scn=2591988, end_scn=2592326:
{"ID":2201,"NAME":"GruwFJBqjDDfbMbEkKWE","VERSION":1}
{"ID":2202,"NAME":"VIzZrPIXIXPBSSjfrcqd","VERSION":1}
{"ID":2203,"NAME":"ibpMSBKpWkBxQuiHMwgi","VERSION":1}
{"ID":2204,"NAME":"rCvDbkVGJdSqgwxmoAuA","VERSION":1}
{"ID":2205,"NAME":"BMmaUgwBiTiahSwmvrLZ","VERSION":1}
{"ID":2206,"NAME":"dhXgcFivntAAdLzjKarA","VERSION":1}
{"ID":2207,"NAME":"JWnqOvhVtWfURKqrDZzG","VERSION":1}
{"ID":2208,"NAME":"frXyfRtDKCOYGtPrfwyq","VERSION":1}
{"ID":2209,"NAME":"TiWCljYEgbINZXcEvfwZ","VERSION":1}
{"ID":2210,"NAME":"amWBKcgmUTlkmWRIUVnc","VERSION":1}

Processing:PART_2592327 begin_scn=2592327, end_scn=2592512:
{"ID":2211,"NAME":"UOaEhUjWcwZbiYsFtFyr","VERSION":1}
{"ID":2212,"NAME":"ACbxBvPQtfAScUKNWWlK","VERSION":1}
{"ID":2213,"NAME":"HGyQstsuFvSqopYzcBYG","VERSION":1}
{"ID":2214,"NAME":"UTTxeoCzkhoHibTqarDR","VERSION":1}
{"ID":2215,"NAME":"osfzKaQEgfXiJaeJLZEJ","VERSION":1}
{"ID":2216,"NAME":"OCPeWDBCPwExYjGWYcue","VERSION":1}
{"ID":2217,"NAME":"fvKGddGaQGDMxVEqdqfs","VERSION":1}
{"ID":2218,"NAME":"zgHsQqdvDEgqBkgaYeVX","VERSION":1}
{"ID":2219,"NAME":"KvsRMNTEUPnemPsbaAax","VERSION":1}
{"ID":2220,"NAME":"RGQyrQwIcRYgOrNgYHGe","VERSION":1}

Processing:PART_2592513 begin_scn=2592513, end_scn=2592703:
{"ID":2203,"NAME":"ibpMSBKpWkBxQuiHMwgi","VERSION":6}
```
