
CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- ================================= Table : Orders ===================================
CREATE TABLE orders (
    order_id VARCHAR(35) PRIMARY KEY,
    customer_id VARCHAR(35),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    delivery_time_days FLOAT,
    delivery_delay_days FLOAT,
    approval_time_hours FLOAT
);
    
SET sql_mode = '';

TRUNCATE TABLE orders;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders_cleaned.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, @purchase_ts, @approved_ts, @carrier_ts, @delivered_ts, @estimated_ts, @delivery_time, @delivery_delay, @approval_time)
SET
    order_purchase_timestamp = NULLIF(@purchase_ts, ''),
    order_approved_at = NULLIF(@approved_ts, ''),
    order_delivered_carrier_date = NULLIF(@carrier_ts, ''),
    order_delivered_customer_date = NULLIF(@delivered_ts, ''),
    order_estimated_delivery_date = NULLIF(@estimated_ts, ''),
    delivery_time_days = NULLIF(@delivery_time, ''),
    delivery_delay_days = NULLIF(@delivery_delay, ''),
    approval_time_hours = NULLIF(@approval_time, '');

SELECT COUNT(*) FROM orders;

-- ========================================== Table : customers ==================================================

SET sql_mode = '';

CREATE TABLE customers (
    customer_id VARCHAR(35) PRIMARY KEY,
    customer_unique_id VARCHAR(35),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(50),
    customer_state VARCHAR(5)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers_cleaned.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- =============================================== Table : sellers =====================================================
CREATE TABLE sellers (
    seller_id VARCHAR(35) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(50),
    seller_state VARCHAR(5)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sellers_cleaned.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- ============================================= Table : category_translation ==================================================

CREATE TABLE category_translation (
    product_category_name VARCHAR(50) PRIMARY KEY,
    product_category_name_english VARCHAR(50)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/category_translation_cleaned.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- ============================================ Table : products =========================================================
CREATE TABLE products (
    product_id VARCHAR(35) PRIMARY KEY,
    product_category_name VARCHAR(50),
    product_name_lenght FLOAT,
    product_description_lenght FLOAT,
    product_photos_qty FLOAT,
    product_weight_g FLOAT,
    product_length_cm FLOAT,
    product_height_cm FLOAT,
    product_width_cm FLOAT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products_cleaned.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- ================================================= Table : order_items ========================================================
CREATE TABLE order_items (
    order_id VARCHAR(35),
    order_item_id INT,
    product_id VARCHAR(35),
    seller_id VARCHAR(35),
    shipping_limit_date DATETIME,
    price FLOAT,
    freight_value FLOAT,
    PRIMARY KEY (order_id, order_item_id)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_items_cleaned.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- ========================================================= Table : order_payments =====================================================
CREATE TABLE order_payments (
    order_id VARCHAR(35),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value FLOAT,
    PRIMARY KEY (order_id, payment_sequential)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_payments_cleaned.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- ======================================================== Table : order_reviews ==========================================================
CREATE TABLE order_reviews (
    review_id VARCHAR(35) PRIMARY KEY,
    order_id VARCHAR(35),
    review_score INT,
    review_comment_title VARCHAR(100),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_reviews_cleaned.csv'
IGNORE INTO TABLE order_reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- ========================================================= Table : geolocation ==========================================================
CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city VARCHAR(50),
    geolocation_state VARCHAR(5)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/geolocation_cleaned.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL SELECT 'orders', COUNT(*) FROM orders; 