----------------------
-- Локации --
----------------------
CREATE TABLE countries (
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE cities (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL,
    state VARCHAR(50),
    country_id INT NOT NULL REFERENCES countries(country_id),
    UNIQUE(city_name, state, country_id)
);

CREATE TABLE postal_codes (
    postal_code_id VARCHAR(20) PRIMARY KEY,
    city_id INT NOT NULL REFERENCES cities(city_id)
);

-------------------------
-- Люди и организации --
-------------------------
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    age INT CHECK (age BETWEEN 0 AND 120),
    email VARCHAR(100) UNIQUE,
    postal_code_id VARCHAR(20) REFERENCES postal_codes(postal_code_id)
);

CREATE TABLE sellers (
    seller_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    postal_code_id VARCHAR(20) REFERENCES postal_codes(postal_code_id)
);

CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE supplier_contacts (
    contact_id SERIAL PRIMARY KEY,
    supplier_id INT REFERENCES suppliers(supplier_id),
    contact_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    UNIQUE(supplier_id, contact_name, email, phone)
);

CREATE TABLE supplier_addresses (
    address_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL REFERENCES suppliers(supplier_id),
    address VARCHAR(200) NOT NULL,
    city_id INT NOT NULL REFERENCES cities(city_id),
    UNIQUE(supplier_id, address)
);

---------------------
-- Товары и категории --
---------------------
CREATE TABLE product_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE product_brands (
    brand_id SERIAL PRIMARY KEY,
    brand_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category_id INT REFERENCES product_categories(category_id),
    price DECIMAL(10, 2) CHECK (price >= 0),
    weight DECIMAL(6, 2),
    color VARCHAR(30),
    size VARCHAR(20),
    brand_id INT REFERENCES product_brands(brand_id),
    material VARCHAR(50),
    description TEXT,
    rating DECIMAL(3, 1) CHECK (rating BETWEEN 0 AND 5),
    reviews INT CHECK (reviews >= 0),
    release_date DATE,
    expiry_date DATE,
    supplier_address_id INT NOT NULL REFERENCES supplier_addresses(address_id)
);

-------------------
-- Питомцы --
-------------------
CREATE TABLE pet_types (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE pet_breeds (
    breed_id SERIAL PRIMARY KEY,
    breed_name VARCHAR(50) NOT NULL,
    type_id INT REFERENCES pet_types(type_id),
    UNIQUE(breed_name, type_id)
);

CREATE TABLE pets (
    pet_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    type_id INT REFERENCES pet_types(type_id),
    breed_id INT REFERENCES pet_breeds(breed_id),
    name VARCHAR(50)
);

-------------------
-- Магазины --
-------------------
CREATE TABLE stores (
    store_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(100),
    city_id INT NOT NULL REFERENCES cities(city_id),
    phone VARCHAR(20),
    email VARCHAR(100),
    UNIQUE(name, address)
);

-----------------------
-- Временное измерение
-----------------------
CREATE TABLE time_dimension (
    date DATE PRIMARY KEY,
    day INT CHECK (day BETWEEN 1 AND 31),
    month INT CHECK (month BETWEEN 1 AND 12),
    year INT CHECK (year > 2000),
    quarter INT CHECK (quarter BETWEEN 1 AND 4),
    day_of_week VARCHAR(9) CHECK (day_of_week IN (
        'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ))
);

-------------------
-- Продажи --
-------------------
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    seller_id INT REFERENCES sellers(seller_id),
    product_id INT REFERENCES products(product_id),
    store_id INT REFERENCES stores(store_id),
    date_id DATE REFERENCES time_dimension(date),
    quantity INT CHECK (quantity > 0),
    total_price DECIMAL(10, 2) CHECK (total_price >= 0)
);




DROP TABLE IF EXISTS postal_codes CASCADE;
DROP TABLE IF EXISTS countries CASCADE;
DROP TABLE IF EXISTS cities CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS supplier_contacts CASCADE;
DROP TABLE IF EXISTS supplier_addresses CASCADE;
DROP TABLE IF EXISTS product_categories CASCADE;
DROP TABLE IF EXISTS product_brands CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS pet_types CASCADE;
DROP TABLE IF EXISTS pet_breeds CASCADE;
DROP TABLE IF EXISTS pets CASCADE;
DROP TABLE IF EXISTS stores CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS time_dimension CASCADE;