CREATE TEMP SEQUENCE import_seq START 1;

DO $$
DECLARE
    file_path TEXT;
    row_count INTEGER;
    temp_table_name TEXT;
    id_offset INTEGER := 0;
    customer_id_offset INTEGER := 0;
    seller_id_offset INTEGER := 0;
    product_id_offset INTEGER := 0;
    file_num INTEGER;
    shift_step INTEGER := 1000;
BEGIN
    FOR file_num IN 1..10 LOOP
        file_path := '/mock_data/MOCK_DATA_' || file_num || '.csv';
        temp_table_name := 'temp_csv_import_' || file_num;
        
        EXECUTE format('CREATE TEMP TABLE %I (LIKE mock_data) ON COMMIT DROP', temp_table_name);
        
        EXECUTE format('COPY %I FROM %L DELIMITER '','' CSV HEADER', temp_table_name, file_path);
        
        EXECUTE format('SELECT COUNT(*) FROM %I', temp_table_name) INTO row_count;
        
        customer_id_offset := (file_num - 1) * shift_step;
        seller_id_offset := (file_num - 1) * shift_step;
        product_id_offset := (file_num - 1) * shift_step;
        
        EXECUTE format('
            INSERT INTO mock_data
            SELECT 
                nextval(''import_seq''),
                customer_first_name,
                customer_last_name,
                customer_age,
                customer_email,
                customer_country,
                customer_postal_code,
                customer_pet_type,
                customer_pet_name,
                customer_pet_breed,
                seller_first_name,
                seller_last_name,
                seller_email,
                seller_country,
                seller_postal_code,
                product_name,
                product_category,
                product_price,
                product_quantity,
                sale_date,
                sale_customer_id + %s,
                sale_seller_id + %s,
                sale_product_id + %s,
                sale_quantity,
                sale_total_price,
                store_name,
                store_location,
                store_city,
                store_state,
                store_country,
                store_phone,
                store_email,
                pet_category,
                product_weight,
                product_color,
                product_size,
                product_brand,
                product_material,
                product_description,
                product_rating,
                product_reviews,
                product_release_date,
                product_expiry_date,
                supplier_name,
                supplier_contact,
                supplier_email,
                supplier_phone,
                supplier_address,
                supplier_city,
                supplier_country
            FROM %I', 
            customer_id_offset, seller_id_offset, product_id_offset, temp_table_name);
        
        RAISE NOTICE 'Импортирован файл % (сдвиг IDs +%). Диапазон ID: % - %', 
            file_path, 
            customer_id_offset,
            currval('import_seq') - row_count + 1,
            currval('import_seq');
            
        EXECUTE format('DROP TABLE %I', temp_table_name);
    END LOOP;
END $$;

DROP SEQUENCE import_seq;