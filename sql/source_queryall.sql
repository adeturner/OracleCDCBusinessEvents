!clear
set serveroutput on lines 2000 pages 1000 trimspool on
exec dbms_output.put_line(CHR(10));
exec dbms_output.put_line( '*** source_query.sql ***' );


exec dbms_output.put_line('*****************************************************');
exec dbms_output.put_line(CHR(10));
set echo on;

select * from source.customer;

select * from source.address order by customer_id;

select * from source.customer_order order by customer_id;

select order_id, count(*) from source.order_detail group by order_id order by 1;

select * from source.delivery;

set echo off;