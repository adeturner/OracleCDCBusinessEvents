set feedback on

CREATE TABLE SOURCE.SOURCE_TABLE1
(
 ID      NUMBER,
 NAME    VARCHAR2(20),
 VERSION NUMBER
 CONSTRAINT "ID_PK" PRIMARY KEY ("ID") USING INDEX COMPUTE STATISTICS TABLESPACE "USERS" ENABLE
) TABLESPACE USERS;

create sequence SOURCE.SOURCE_TABLE1_SEQ start with 1;

CREATE TABLE SOURCE.SOURCE_TABLE2
( 
 ID                 NUMBER,
 SOURCE_TABLE1_ID   NUMBER,
 NAME               VARCHAR2(20),
 VERSION            NUMBER,
 CONSTRAINT ID2_PK PRIMARY KEY ("ID") USING INDEX COMPUTE STATISTICS TABLESPACE "USERS" ENABLE,
 CONSTRAINT ID2_FK FOREIGN KEY (SOURCE_TABLE1_ID) REFERENCES SOURCE.SOURCE_TABLE1(ID)
) TABLESPACE USERS;

create sequence SOURCE.SOURCE_TABLE2_SEQ start with 1;

CREATE TABLE SOURCE.SOURCE_TABLE3
(
 ID                 NUMBER,
 SOURCE_TABLE1_ID   NUMBER,
 NAME               VARCHAR2(20),
 VERSION            NUMBER,
 CONSTRAINT "ID3_PK" PRIMARY KEY ("ID") USING INDEX COMPUTE STATISTICS TABLESPACE "USERS" ENABLE,
 CONSTRAINT ID3_FK FOREIGN KEY (SOURCE_TABLE1_ID) REFERENCES SOURCE.SOURCE_TABLE1(ID)
) TABLESPACE USERS;

create sequence SOURCE.SOURCE_TABLE3_SEQ start with 1;

-- ###############################################################################################
-- ###############################################################################################

CREATE TABLE TARGET.TARGET_TABLE1
("PK" CHAR(13),
 "MODIFY_TIME" TIMESTAMP (6),
 "RID" ROWID,
 SCNNO NUMBER,
 OPTYPE CHAR
) 
PARTITION BY RANGE (SCNNO) 
  (PARTITION part_0 VALUES LESS THAN (maxvalue) TABLESPACE USERS);
  
grant insert, update, delete on target.target_table1 to ogg_apply;

CREATE TABLE TARGET.TARGET_TABLE2
("PK" CHAR(13),
 "MODIFY_TIME" TIMESTAMP (6),
 "RID" ROWID,
 SCNNO NUMBER,
 OPTYPE CHAR
) 
PARTITION BY RANGE (SCNNO) 
  (PARTITION part_0 VALUES LESS THAN (maxvalue) TABLESPACE USERS);
  
grant insert, update, delete on target.target_table2 to ogg_apply;

CREATE TABLE TARGET.TARGET_TABLE3
("PK" CHAR(13),
 "MODIFY_TIME" TIMESTAMP (6),
 "RID" ROWID,
 SCNNO NUMBER,
 OPTYPE CHAR
) 
PARTITION BY RANGE (SCNNO) 
  (PARTITION part_0 VALUES LESS THAN (maxvalue) TABLESPACE USERS);
  
grant insert, update, delete on target.target_table3 to ogg_apply;

CREATE TABLE TARGET.PARTITION_CONFIG
( 
 MODULE_NAME VARCHAR2(20),
 PARTITION_NAME VARCHAR2(20),
 BEGIN_SCN NUMBER,
 END_SCN NUMBER
) SEGMENT CREATION IMMEDIATE
TABLESPACE USERS;

create sequence target.partition_seq start with 1;


-- ###############################################################################################
-- ###############################################################################################

CREATE TABLE TARGET.MASTER_SOURCE_TABLE1
(
 RID      ROWID,
 SCNNO   NUMBER
)
PARTITION BY RANGE (SCNNO) 
  (PARTITION part_0 VALUES LESS THAN (maxvalue) TABLESPACE USERS);