-------------------------
-- Заполнение локаций
-------------------------

INSERT INTO countries (country_name)
SELECT DISTINCT source_country FROM (
    SELECT customer_country AS source_country FROM mock_data
    UNION SELECT seller_country FROM mock_data
    UNION SELECT store_country FROM mock_data
    UNION SELECT supplier_country FROM mock_data
) AS all_countries
WHERE source_country IS NOT NULL
ON CONFLICT (country_name) DO NOTHING;

INSERT INTO cities (city_name, state, country_id)
SELECT DISTINCT 
    md.store_city AS city_name,
    md.store_state AS state,
    c.country_id
FROM mock_data md
JOIN countries c ON md.store_country = c.country_name
ON CONFLICT (city_name, state, country_id) DO NOTHING;

INSERT INTO cities (city_name, state, country_id)
SELECT DISTINCT 
    md.supplier_city AS city_name,
    NULL::VARCHAR(50) AS state,
    c.country_id
FROM mock_data md
JOIN countries c ON md.supplier_country = c.country_name
ON CONFLICT (city_name, state, country_id) DO NOTHING;

INSERT INTO postal_codes (postal_code_id, city_id)
SELECT DISTINCT 
    md.customer_postal_code,
    ct.city_id
FROM mock_data md
JOIN cities ct ON md.store_city = ct.city_name
JOIN countries cn ON ct.country_id = cn.country_id AND cn.country_name = md.customer_country
WHERE md.customer_postal_code IS NOT NULL
ON CONFLICT (postal_code_id) DO NOTHING;

-----------------------------------------------------
-- Поставщики и магазины
-----------------------------------------------------

INSERT INTO suppliers (name)
SELECT DISTINCT supplier_name 
FROM mock_data 
ON CONFLICT (name) DO NOTHING;

INSERT INTO supplier_contacts (supplier_id, contact_name, email, phone)
SELECT 
    s.supplier_id,
    md.supplier_contact,
    md.supplier_email,
    md.supplier_phone
FROM mock_data md
JOIN suppliers s ON md.supplier_name = s.name
ON CONFLICT (supplier_id, contact_name, email, phone) DO NOTHING;

INSERT INTO supplier_addresses (supplier_id, address, city_id)
SELECT 
    s.supplier_id,
    md.supplier_address,
    ct.city_id
FROM mock_data md
JOIN suppliers s ON md.supplier_name = s.name
JOIN cities ct 
    ON md.supplier_city = ct.city_name 
    AND md.supplier_country = (SELECT country_name FROM countries WHERE country_id = ct.country_id)
ON CONFLICT (supplier_id, address) DO NOTHING;

INSERT INTO stores (name, address, city_id, phone, email)
SELECT DISTINCT
    md.store_name,
    md.store_location,
    ct.city_id,
    md.store_phone,
    md.store_email
FROM mock_data md
JOIN cities ct 
    ON md.store_city = ct.city_name 
    AND md.store_country = (SELECT country_name FROM countries WHERE country_id = ct.country_id)
ON CONFLICT (name, address) DO NOTHING;

-----------------------------------------------------
-- Категории и бренды товаров
-----------------------------------------------------

INSERT INTO product_categories (category_name)
SELECT DISTINCT 
    product_category 
FROM mock_data 
WHERE product_category IS NOT NULL
ON CONFLICT (category_name) DO NOTHING;

INSERT INTO product_brands (brand_name)
SELECT DISTINCT 
    product_brand 
FROM mock_data 
WHERE product_brand IS NOT NULL
ON CONFLICT (brand_name) DO NOTHING;

-----------------------------------------------------
-- Товары
-----------------------------------------------------
INSERT INTO products (
    product_id, 
    name, 
    category_id,
    price,
    weight,
    color,
    size,
    brand_id,
    material,
    description,
    rating,
    reviews,
    release_date,
    expiry_date,
    supplier_address_id
)
SELECT 
    md.id,
    md.product_name,
    pc.category_id,
    md.product_price,
    md.product_weight,
    md.product_color,
    md.product_size,
    pb.brand_id,
    md.product_material,
    md.product_description,
    md.product_rating,
    md.product_reviews,
    md.product_release_date::DATE,
    md.product_expiry_date::DATE,
    sa.address_id
FROM mock_data md
JOIN product_categories pc ON md.product_category = pc.category_name
JOIN product_brands pb ON md.product_brand = pb.brand_name
JOIN suppliers s ON md.supplier_name = s.name
JOIN (
    SELECT 
        c.city_id,
        c.city_name,
        cntr.country_name
    FROM cities c
    JOIN countries cntr ON c.country_id = cntr.country_id
) AS loc ON md.supplier_city = loc.city_name 
        AND md.supplier_country = loc.country_name
JOIN supplier_addresses sa 
    ON s.supplier_id = sa.supplier_id 
    AND md.supplier_address = sa.address
    AND sa.city_id = loc.city_id
ON CONFLICT (product_id) DO NOTHING;

-----------------------------------------------------
-- Клиенты и продавцы
-----------------------------------------------------

-- Клиенты
INSERT INTO customers (customer_id, first_name, last_name, age, email, postal_code_id)
SELECT 
    md.sale_customer_id,
    md.customer_first_name,
    md.customer_last_name,
    md.customer_age,
    md.customer_email,
    pc.postal_code_id
FROM mock_data md
LEFT JOIN postal_codes pc ON md.customer_postal_code = pc.postal_code_id
ON CONFLICT (customer_id) DO NOTHING;

-- Продавцы
INSERT INTO sellers (seller_id, first_name, last_name, email, postal_code_id)
SELECT 
    md.id,
    md.seller_first_name,
    md.seller_last_name,
    md.seller_email,
    pc.postal_code_id
FROM mock_data md
LEFT JOIN postal_codes pc ON md.seller_postal_code = pc.postal_code_id
ON CONFLICT (seller_id) DO NOTHING;

-----------------------------------------------------
-- Данные о питомцах
-----------------------------------------------------

INSERT INTO pet_types (type_name)
SELECT DISTINCT 
    customer_pet_type 
FROM mock_data 
WHERE customer_pet_type IS NOT NULL
ON CONFLICT (type_name) DO NOTHING;

INSERT INTO pet_breeds (breed_name, type_id)
SELECT DISTINCT
    md.customer_pet_breed,
    pt.type_id
FROM mock_data md
JOIN pet_types pt ON md.customer_pet_type = pt.type_name
WHERE md.customer_pet_breed IS NOT NULL
ON CONFLICT (breed_name, type_id) DO NOTHING;

INSERT INTO pets (customer_id, type_id, breed_id, name)
SELECT
    c.customer_id,
    pt.type_id,
    pb.breed_id,
    md.customer_pet_name
FROM mock_data md
JOIN customers c ON md.id = c.customer_id
JOIN pet_types pt ON md.customer_pet_type = pt.type_name
LEFT JOIN pet_breeds pb 
    ON md.customer_pet_breed = pb.breed_name 
    AND pt.type_id = pb.type_id;

-----------------------------------------------------
-- Временное измерение 
-----------------------------------------------------

INSERT INTO time_dimension (date, day, month, year, quarter, day_of_week)
SELECT
    sale_date,
    EXTRACT(DAY FROM sale_date),
    EXTRACT(MONTH FROM sale_date),
    EXTRACT(YEAR FROM sale_date),
    EXTRACT(QUARTER FROM sale_date),
    TRIM(TO_CHAR(sale_date, 'Day'))  
FROM (
    SELECT DISTINCT sale_date FROM mock_data
) AS dates
ON CONFLICT (date) DO NOTHING;

-----------------------------------------------------
-- Продажи 
-----------------------------------------------------

INSERT INTO sales (
    sale_id,
    customer_id,
    seller_id,
    product_id,
    store_id,
    date_id,
    quantity,
    total_price
)
SELECT
    md.id,
    c.customer_id,
    s.seller_id,
    p.product_id,
    st.store_id,
    td.date,  
    md.sale_quantity,
    md.sale_total_price
FROM mock_data md
JOIN customers c ON md.sale_customer_id = c.customer_id
JOIN sellers s ON md.sale_seller_id = s.seller_id
JOIN products p ON md.sale_product_id = p.product_id
JOIN stores st ON md.store_name = st.name AND md.store_location = st.address
JOIN time_dimension td ON md.sale_date = td.date;