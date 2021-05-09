
# Using Goldengate Change Data Capture to generate infrequent and whole business events

## Introduction

A common pattern is to integrate an on-prem oracle database with a modernised cloud environment to support, for example, a strangler pattern

Goldengate for Big Data generates record by record events that can be streamed to e.g. Kafka.  

But For some databases change data capture generates a large amount of change volume and requires scaling e.g. through multiple kafka consumers.

In these scenarios we are unlikely to maintain transactional consistency of business objects, as individual CDC records may not be processed in order.

**In this repo we demonstrate an eventually consistent method to generate a proportionately low volume of transactionally consistent business events from a high volume change data capture stream**

We present two POCs

- POC #1 is the first attempt, which resulted in row by row processing that potentially has high impact on the source system and may not scale well.

- POC #2 (in flight) builds on learnings to allow scaleable set processing whilst ensuring that all the activity happens on the target system and not the source.

## Setup

1. Follow 1_dockerSetup.md

2. Follow 2_oggSetup.md

3. Follow the README in the appropriate POC directory

## Key files

Both POCs use the same structure:

- sql/*.sql are supporting files that work for both POCs

- ogg/*.sh are supporting files that work for both POCs

In each POC directory the key files of note are:

- env.sh is a pre-req for the POC and configures the environment

- schema_ddl.sql

- poc_pkg.sql is the core of the code

- poc_e2e.sql runs the end to end proof of concept

- poc_cleanup.sql tidies up
