
# Using Goldengate Change Data Capture to generate infrequent and whole business events

A common pattern is to integrate an on-prem oracle database with a modernised cloud environment to support, for example, a strangler pattern

Goldengate for Big Data generates record by record events that can be streamed to e.g. Kafka.  But For some databases change data capture generates a large amount of change volume and scaling (e.g. through multiple kafka consumers) is likely to mean that we cannot respect transaction boundaries.

This repo demonstrates an eventually consistent method to use Goldengate to generate a limited volume of whole transactionally consistent business events.

## Setup database environment

Follow 1_dockerSetup.md

## Setup ogg environment

Follow 2_oggSetup.md

## Setup PoC

Follow 3_pocSchemaSetup.md

## Test the PoC

### testdata_e2e1

Expected output:

```code
@testdata_e2e1

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
```

