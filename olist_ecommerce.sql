CREATE DATABASE olist_ecommerce;

USE olist_ecommerce;

SHOW GLOBAL VARIABLES LIKE 'local_infile';

CREATE TABLE olist_customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32),
    customer_zip_code_prefix CHAR(5),
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

LOAD DATA LOCAL INFILE
"C:/Users/ASUS/OneDrive/Desktop/data analytics/Olist - SQL Project/olist_customers_dataset.csv"
INTO TABLE olist_customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 1. Sellers
CREATE TABLE olist_sellers (
    seller_id CHAR(32) PRIMARY KEY,
    seller_zip_code_prefix CHAR(5),
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

-- 1. Sellers
LOAD DATA LOCAL INFILE
'C:/Users/ASUS/OneDrive/Desktop/data analytics/Olist - SQL Project/olist_sellers_dataset.csv'
INTO TABLE olist_sellers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 2. Products
CREATE TABLE olist_products (
    product_id CHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g DECIMAL(10,2),
    product_length_cm DECIMAL(10,2),
    product_height_cm DECIMAL(10,2),
    product_width_cm DECIMAL(10,2)
);

-- 2. Products
LOAD DATA LOCAL INFILE
'C:/Users/ASUS/OneDrive/Desktop/data analytics/Olist - SQL Project/olist_products_dataset.csv'
INTO TABLE olist_products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT
    COUNT(*) AS total_rows,
    SUM(product_name_lenght IS NULL) AS missing_name_length,
    SUM(product_description_lenght IS NULL) AS missing_description,
    SUM(product_weight_g IS NULL) AS missing_weight
FROM olist_products;

SELECT
    SUM(product_name_lenght = 0) AS zero_name_length,
    SUM(product_description_lenght = 0) AS zero_description,
    SUM(product_photos_qty = 0) AS zero_photos,
    SUM(product_weight_g = 0) AS zero_weight,
    SUM(product_length_cm = 0) AS zero_length,
    SUM(product_height_cm = 0) AS zero_height,
    SUM(product_width_cm = 0) AS zero_width
FROM olist_products;

DESCRIBE olist_products;

TRUNCATE TABLE olist_products;

LOAD DATA LOCAL INFILE
'C:/Users/ASUS/OneDrive/Desktop/data analytics/Olist - SQL Project/olist_products_dataset.csv'
INTO TABLE olist_products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    product_id,
    @category,
    @name_length,
    @description_length,
    @photos_qty,
    @weight,
    @length,
    @height,
    @width
)
SET
    product_category_name = NULLIF(@category, ''),
    product_name_lenght = NULLIF(@name_length, ''),
    product_description_lenght = NULLIF(@description_length, ''),
    product_photos_qty = NULLIF(@photos_qty, ''),
    product_weight_g = NULLIF(@weight, ''),
    product_length_cm = NULLIF(@length, ''),
    product_height_cm = NULLIF(@height, ''),
    product_width_cm = NULLIF(@width, '');
    
-- 3. Category Translation
CREATE TABLE olist_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

-- 3. Category Translation
LOAD DATA LOCAL INFILE
'C:/Users/ASUS/OneDrive/Desktop/data analytics/Olist - SQL Project/product_category_name_translation.csv'
INTO TABLE olist_category_translation
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- 4. Orders
CREATE TABLE olist_orders (
    order_id CHAR(32) PRIMARY KEY,
    customer_id CHAR(32),
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

-- 4. Orders
LOAD DATA LOCAL INFILE
'C:/Users/ASUS/OneDrive/Desktop/data analytics/Olist - SQL Project/olist_orders_dataset.csv'
INTO TABLE olist_orders
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW WARNINGS;

SELECT COUNT(*) AS total_orders
FROM olist_orders;

DESCRIBE olist_orders;

SELECT
    COUNT(*) AS total_orders,
    SUM(order_delivered_carrier_date IS NULL)
    AS missing_carrier_dates,
    SUM(order_delivered_customer_date IS NULL)
    AS missing_customer_dates
FROM olist_orders;

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM olist_orders
GROUP BY order_status
ORDER BY total_orders DESC;

SELECT
    order_status,
    COUNT(*) AS total_orders,

    SUM(order_delivered_carrier_date IS NULL)
    AS missing_carrier_dates,

    SUM(order_delivered_customer_date IS NULL)
    AS missing_customer_dates

FROM olist_orders
GROUP BY order_status
ORDER BY total_orders DESC;

SELECT
    order_id,
    order_status,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM olist_orders
WHERE order_status <> 'delivered'
LIMIT 20;

SELECT
    COUNT(*) AS total_orders,
    SUM(CAST(order_delivered_carrier_date AS CHAR)
        = '0000-00-00 00:00:00') AS missing_carrier_dates,
    SUM(CAST(order_delivered_customer_date AS CHAR)
        = '0000-00-00 00:00:00') AS missing_customer_dates
FROM olist_orders;

SET SQL_SAFE_UPDATES = 0;

SELECT @@SQL_SAFE_UPDATES;

UPDATE olist_orders
SET order_delivered_carrier_date = NULL
WHERE CAST(order_delivered_carrier_date AS CHAR)
= '0000-00-00 00:00:00';

UPDATE olist_orders
SET order_delivered_customer_date = NULL
WHERE CAST(order_delivered_customer_date AS CHAR)
= '0000-00-00 00:00:00';

SELECT
    COUNT(*) AS total_orders,
    SUM(order_delivered_carrier_date IS NULL) AS missing_carrier_dates,
    SUM(order_delivered_customer_date IS NULL) AS missing_customer_dates
FROM olist_orders;

SET SQL_SAFE_UPDATES = 1;

show tables;

-- 5. Order Items
CREATE TABLE olist_order_items (
    order_id CHAR(32),
    order_item_id INT,
    product_id CHAR(32),
    seller_id CHAR(32),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

-- 5. Order Items
LOAD DATA LOCAL INFILE
'C:/Users/ASUS/OneDrive/Desktop/data analytics/Olist - SQL Project/olist_order_items_dataset.csv'
INTO TABLE olist_order_items
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 6. Order Payments
CREATE TABLE olist_order_payments (
    order_id CHAR(32),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- 6. Order Payments
LOAD DATA LOCAL INFILE
'C:/Users/ASUS/OneDrive/Desktop/data analytics/Olist - SQL Project/olist_order_payments_dataset.csv'
INTO TABLE olist_order_payments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 7. Order Reviews
CREATE TABLE olist_order_reviews (
    review_id CHAR(32) PRIMARY KEY,
    order_id CHAR(32),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

-- 7. Order Reviews
LOAD DATA LOCAL INFILE
'C:/Users/ASUS/OneDrive/Desktop/data analytics/Olist - SQL Project/olist_order_reviews_dataset.csv'
INTO TABLE olist_order_reviews
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW WARNINGS;

SELECT COUNT(*) AS total_reviews
FROM olist_order_reviews;

DESCRIBE olist_order_reviews;

SELECT
    review_creation_date,
    review_answer_timestamp
FROM olist_order_reviews
LIMIT 10;

-- Check total reviews
SELECT COUNT(*) AS total_reviews
FROM olist_order_reviews;

-- Check review score distribution
SELECT
    review_score,
    COUNT(*) AS total_reviews
FROM olist_order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Check missing review scores
SELECT COUNT(*) AS missing_scores
FROM olist_order_reviews
WHERE review_score IS NULL;

-- Check date columns
SELECT
    MIN(review_creation_date),
    MAX(review_creation_date),
    MIN(review_answer_timestamp),
    MAX(review_answer_timestamp)
FROM olist_order_reviews;

SELECT COUNT(*) AS missing_scores
FROM olist_order_reviews
WHERE review_score IS NULL;

SELECT
    COUNT(*) AS total_reviews,

    SUM(
        CAST(review_creation_date AS CHAR)
        = '0000-00-00 00:00:00'
    ) AS invalid_creation_dates,

    SUM(
        CAST(review_answer_timestamp AS CHAR)
        = '0000-00-00 00:00:00'
    ) AS invalid_answer_dates

FROM olist_order_reviews;

SET SQL_SAFE_UPDATES = 0;

UPDATE olist_order_reviews
SET review_creation_date = NULL
WHERE CAST(review_creation_date AS CHAR)
= '0000-00-00 00:00:00';

UPDATE olist_order_reviews
SET review_answer_timestamp = NULL
WHERE CAST(review_answer_timestamp AS CHAR)
= '0000-00-00 00:00:00';

SET SQL_SAFE_UPDATES = 1;

SELECT
    MIN(review_creation_date) AS min_creation_date,
    MAX(review_creation_date) AS max_creation_date,
    MIN(review_answer_timestamp) AS min_answer_date,
    MAX(review_answer_timestamp) AS max_answer_date
FROM olist_order_reviews;

-- Total reviews
SELECT COUNT(*) AS total_reviews
FROM olist_order_reviews;

-- Missing review scores
SELECT COUNT(*) AS missing_scores
FROM olist_order_reviews
WHERE review_score IS NULL;

-- Check invalid dates
SELECT
    COUNT(*) AS total_reviews,
    SUM(review_creation_date IS NULL) AS missing_creation_dates,
    SUM(review_answer_timestamp IS NULL) AS missing_answer_dates
FROM olist_order_reviews;

-- Review score distribution
SELECT
    review_score,
    COUNT(*) AS total_reviews
FROM olist_order_reviews
GROUP BY review_score
ORDER BY review_score;

show tables;

CREATE TABLE olist_geolocation (
    geolocation_zip_code_prefix VARCHAR(5),
    geolocation_lat DECIMAL(10,8),
    geolocation_lng DECIMAL(11,8),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);

LOAD DATA LOCAL INFILE
'C:/Users/ASUS/OneDrive/Desktop/data analytics/Olist - SQL Project/olist_geolocation_dataset.csv'
INTO TABLE olist_geolocation
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW WARNINGS;

SELECT COUNT(*) AS total_records
FROM olist_geolocation;

SELECT *
FROM olist_geolocation
LIMIT 10;

DESCRIBE olist_geolocation;

SELECT
    COUNT(*) AS total_records,
    SUM(geolocation_lat IS NULL) AS null_latitude,
    SUM(geolocation_lng IS NULL) AS null_longitude,
    SUM(geolocation_city IS NULL) AS null_city
FROM olist_geolocation;

SELECT
    MIN(geolocation_lat) AS min_latitude,
    MAX(geolocation_lat) AS max_latitude,
    MIN(geolocation_lng) AS min_longitude,
    MAX(geolocation_lng) AS max_longitude
FROM olist_geolocation;

show tables;