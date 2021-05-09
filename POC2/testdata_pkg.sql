CREATE OR REPLACE PACKAGE source.testdata_pkg AS 

	procedure insert_testdata;
    procedure update_testdata(p_customer_id number);

END testdata_pkg; 
/
show errors

CREATE OR REPLACE PACKAGE BODY source.testdata_pkg AS 

	procedure insert_testdata
	is
	begin

        insert into source.customer (id, name, version) 
        values (source.customer_seq.nextval, 
                dbms_random.string(opt=>'A', len=>20), 1);

        for i in 1..2
        loop

            insert into source.address (id, customer_id, ADDRESS, version)
            values (source.address_seq.nextval, 
                    source.customer_seq.currval, 
                    dbms_random.string(opt=>'A', len=>20), 1);

            for j in 1..2
            loop

                insert into source.customer_order (id, customer_id, name, version)
                values (source.customer_order_seq.nextval, 
                        source.customer_seq.currval,
                        dbms_random.string(opt=>'A', len=>20), 1);

                for k in 1..5
                loop
                    insert into source.order_detail (id, order_id, DETAIL, version)
                    values (source.order_detail_seq.nextval, 
                            source.customer_order_seq.currval, 
                            dbms_random.string(opt=>'A', len=>20), 1);
                end loop;

                insert into source.delivery (id, order_id, address_id, name, version)
                values (source.delivery_seq.nextval, 
                        source.customer_order_seq.currval, 
                        source.address_seq.currval, 
                        dbms_random.string(opt=>'A', len=>20), 1);

            end loop;

        end loop;

        commit;

    end insert_testdata;

   	procedure update_testdata(p_customer_id number)
	is
        l_max_address_id number;
        l_max_delivery_id number;
        l_max_order_id number;
        l_min_order_id number;
	begin

        -- ADDRESS
        select max(id) into l_max_address_id 
        from  source.address 
        where customer_id = p_customer_id;

        update source.address 
        set version=version+1, 
            address=dbms_random.string(opt=>'A', len=>20)
        where customer_id = p_customer_id
        and   id =l_max_address_id;

        -- DELIVERY
        select max(id), max(order_id), min(order_id)
        into l_max_delivery_id, l_max_order_id, l_min_order_id
        from  source.delivery d
        where d.address_id = l_max_address_id;

        update source.delivery
        set version=version+1, 
            name=dbms_random.string(opt=>'A', len=>20)
        where address_id = l_max_address_id
        and   order_id = l_max_order_id;

        delete from source.delivery
        where address_id = l_max_address_id
        and   order_id = l_min_order_id;
        
        commit;

    end update_testdata;

end testdata_pkg;
/
show errors

	


/*
For reference

TABLE_NAME           COLUMN_NAME
-------------------- --------------------------------------------------------------------------------------------------------------------------------
ADDRESS              ID
ADDRESS              CUSTOMER_ID
ADDRESS              ADDRESS
ADDRESS              VERSION
CUSTOMER             ID
CUSTOMER             NAME
CUSTOMER             VERSION
CUSTOMER_ORDER       ID
CUSTOMER_ORDER       CUSTOMER_ID
CUSTOMER_ORDER       NAME
CUSTOMER_ORDER       VERSION
DELIVERY             ID
DELIVERY             ORDER_ID
DELIVERY             ADDRESS_ID
DELIVERY             NAME
DELIVERY             VERSION
ORDER_DETAIL         ID
ORDER_DETAIL         ORDER_ID
ORDER_DETAIL         DETAIL
ORDER_DETAIL         VERSION
*/
