INSERT INTO customers (full_name, email) VALUES ('John Smith', 'john@example.com');
INSERT INTO customers (full_name, email) VALUES ('Anna Brown', 'anna@example.com');
INSERT INTO products (product_name, price, stock_quantity) VALUES ('Laptop', 1200.00, 10);
INSERT INTO products (product_name, price, stock_quantity) VALUES ('Mouse', 25.00, 100);

CALL create_order(1);

SELECT * FROM order_log;

CALL add_product_to_order(1, 1, 1);
CALL add_product_to_order(1, 2, 2);

SELECT order_id, total_amount FROM orders WHERE order_id = 1; 

SELECT product_id, product_name, stock_quantity FROM products; 

--Error check:
-- CALL add_product_to_order(1, 1, 20); -- Uncomment for test
