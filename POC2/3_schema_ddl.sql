set feedback on

-- #############################################################################################
-- TARGET PARTITION CONFIG
-- #############################################################################################

CREATE TABLE TARGET.PARTITION_CONFIG
( 
 MODULE_NAME VARCHAR2(20),
 PARTITION_NAME VARCHAR2(20),
 BEGIN_SCN NUMBER,
 END_SCN NUMBER
) SEGMENT CREATION IMMEDIATE
TABLESPACE USERS;

create sequence target.partition_seq start with 1;


-- #############################################################################################
-- SOURCE SCHEMA
-- #############################################################################################

CREATE TABLE SOURCE.CUSTOMER
(
 ID      NUMBER,
 NAME    VARCHAR2(20),
 VERSION NUMBER,
 CONSTRAINT CUSTOMER_PK PRIMARY KEY (ID) USING INDEX COMPUTE STATISTICS TABLESPACE "USERS" ENABLE
) TABLESPACE USERS;

create sequence SOURCE.customer_seq start with 1;

-- #############################################################################################

CREATE TABLE SOURCE.CUSTOMER_ORDER
(
 ID            NUMBER,
 CUSTOMER_ID   NUMBER,
 NAME          VARCHAR2(200),
 VERSION NUMBER,
 CONSTRAINT ORDER_PK PRIMARY KEY (ID) USING INDEX COMPUTE STATISTICS TABLESPACE "USERS" ENABLE,
 CONSTRAINT ORDER_FK FOREIGN KEY (CUSTOMER_ID) REFERENCES SOURCE.CUSTOMER(ID)
) TABLESPACE USERS;

create sequence SOURCE.CUSTOMER_ORDER_seq start with 1;

-- #############################################################################################

CREATE TABLE SOURCE.order_detail
(
 ID         NUMBER,
 ORDER_ID   NUMBER,
 DETAIL     VARCHAR2(200),
 VERSION    NUMBER,
 CONSTRAINT ORDER_DETAIL_PK PRIMARY KEY (ID) USING INDEX COMPUTE STATISTICS TABLESPACE "USERS" ENABLE,
 CONSTRAINT ORDER_DETAIL_FK FOREIGN KEY (ORDER_ID) REFERENCES SOURCE.CUSTOMER_ORDER(ID)
) TABLESPACE USERS;

create sequence SOURCE.order_detail_seq start with 1;

-- #############################################################################################

CREATE TABLE SOURCE.address
(
 ID          NUMBER,
 CUSTOMER_ID NUMBER,
 ADDRESS     VARCHAR2(200),
 VERSION     NUMBER,
 CONSTRAINT ADDRESS_PK PRIMARY KEY (ID) USING INDEX COMPUTE STATISTICS TABLESPACE "USERS" ENABLE,
 CONSTRAINT ADDRESS_FK FOREIGN KEY (CUSTOMER_ID) REFERENCES SOURCE.CUSTOMER(ID)
) TABLESPACE USERS;

create sequence SOURCE.address_seq start with 1;

-- #############################################################################################

CREATE TABLE SOURCE.delivery
(
 ID            NUMBER,
 ORDER_ID      NUMBER,
 ADDRESS_ID    NUMBER,
 NAME          VARCHAR2(200),
 VERSION       NUMBER,
 CONSTRAINT DELIVERY_PK PRIMARY KEY (ID) USING INDEX COMPUTE STATISTICS TABLESPACE "USERS" ENABLE,
 CONSTRAINT DELIVERY_FK1 FOREIGN KEY (ORDER_ID) REFERENCES SOURCE.CUSTOMER_ORDER(ID),
 CONSTRAINT DELIVERY_FK2 FOREIGN KEY (ADDRESS_ID) REFERENCES SOURCE.ADDRESS(ID)
) TABLESPACE USERS;

create sequence SOURCE.delivery_seq start with 1;


-- #############################################################################################
-- TARGET SCHEMA
-- #############################################################################################

CREATE TABLE TARGET.CUSTOMER
(
 ID      NUMBER,
 "RID" ROWID,
 SCNNO NUMBER,
 OPTYPE CHAR
)
PARTITION BY RANGE (SCNNO) 
  (PARTITION part_0 VALUES LESS THAN (maxvalue) TABLESPACE USERS);

-- #############################################################################################

CREATE TABLE TARGET.CUSTOMER_ORDER
(
 ID            NUMBER,
 CUSTOMER_ID   NUMBER,
 "RID" ROWID,
 SCNNO NUMBER,
 OPTYPE CHAR
)
PARTITION BY RANGE (SCNNO) 
  (PARTITION part_0 VALUES LESS THAN (maxvalue) TABLESPACE USERS);

-- #############################################################################################

CREATE TABLE TARGET.order_detail
(
 ID         NUMBER,
 ORDER_ID   NUMBER,
 "RID" ROWID,
 SCNNO NUMBER,
 OPTYPE CHAR
)
PARTITION BY RANGE (SCNNO) 
  (PARTITION part_0 VALUES LESS THAN (maxvalue) TABLESPACE USERS);

-- #############################################################################################

CREATE TABLE TARGET.address
(
 ID          NUMBER,
 CUSTOMER_ID NUMBER,
 "RID" ROWID,
 SCNNO NUMBER,
 OPTYPE CHAR
)
PARTITION BY RANGE (SCNNO) 
  (PARTITION part_0 VALUES LESS THAN (maxvalue) TABLESPACE USERS);


-- #############################################################################################

CREATE TABLE TARGET.delivery
(
 ID            NUMBER,
 ORDER_ID      NUMBER,
 ADDRESS_ID    NUMBER,
 "RID" ROWID,
 SCNNO NUMBER,
 OPTYPE CHAR
)
PARTITION BY RANGE (SCNNO) 
  (PARTITION part_0 VALUES LESS THAN (maxvalue) TABLESPACE USERS);

-- #############################################################################################

CREATE TABLE TARGET.MASTER_CUSTOMER
(
 RID      ROWID,
 SCNNO   NUMBER,
 OPTYPE   CHAR
)
PARTITION BY RANGE (SCNNO) 
  (PARTITION part_0 VALUES LESS THAN (maxvalue) TABLESPACE USERS);

-- #############################################################################################

CREATE TABLE TARGET.SCHEMA_METADATA
(
    child_level     number,
		master_table    varchar2(30),
		master_pk       varchar2(30),
		childL1_table   varchar2(30),
		childL1_pk_col  varchar2(30),
		childL1_fk_col  varchar2(30),
		childL2_table   varchar2(30),
		childL2_pk_col  varchar2(30),
		childL2_fk_col  varchar2(30)
)
TABLESPACE USERS;

truncate table TARGET.SCHEMA_METADATA;
insert into TARGET.SCHEMA_METADATA VALUES (0, 'CUSTOMER', 'ID', null, null, null, null, null, null );
insert into TARGET.SCHEMA_METADATA VALUES (1, 'CUSTOMER', 'ID', 'CUSTOMER_ORDER', 'ID', 'CUSTOMER_ID', null, null, null );
insert into TARGET.SCHEMA_METADATA VALUES (1, 'CUSTOMER', 'ID', 'ADDRESS', 'ID', 'CUSTOMER_ID', null, null, null );
insert into TARGET.SCHEMA_METADATA VALUES (2, 'CUSTOMER', 'ID', 'CUSTOMER_ORDER', 'ID', 'CUSTOMER_ID', 'ORDER_DETAIL', 'ID', 'ORDER_ID' );
insert into TARGET.SCHEMA_METADATA VALUES (2, 'CUSTOMER', 'ID', 'ADDRESS', 'ID', 'CUSTOMER_ID', 'DELIVERY', 'ID', 'ADDRESS_ID' );
commit;


grant insert, update, delete on target.customer to ogg_apply;
grant insert, update, delete on target.customer_order to ogg_apply;
grant insert, update, delete on target.address to ogg_apply;
grant insert, update, delete on target.order_detail to ogg_apply;
grant insert, update, delete on target.delivery to ogg_apply;

