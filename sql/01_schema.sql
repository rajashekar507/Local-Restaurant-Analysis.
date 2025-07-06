-- 01_schema.sql: Database and table creation

-- Create database (if not exists)
-- CREATE DATABASE danny_diner; -- Uncomment if running outside a managed environment

-- Table: sales
CREATE TABLE sales (
    customer_id VARCHAR(1),
    order_date DATE,
    product_id INTEGER
);

-- Table: menu
CREATE TABLE menu (
    product_id INTEGER,
    product_name VARCHAR(5),
    price INTEGER
);

-- Table: members
CREATE TABLE members (
    customer_id VARCHAR(1),
    join_date DATE
); 