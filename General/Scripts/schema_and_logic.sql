--DATABASE structure
DROP TABLE IF EXISTS order_log CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE IF NOT EXISTS customers (
    customer_id serial primary key,
    full_name varchar(100) not null,
    email varchar(100) unique not null,
    balance numeric(10,2) default 0
);

CREATE TABLE IF NOT EXISTS products (
    product_id serial primary key,
    product_name varchar(100) not null,
    price numeric(10,2) not null,
    stock_quantity int not null
);

CREATE TABLE IF NOT EXISTS orders (
    order_id serial primary key,
    customer_id int references customers(customer_id),
    order_date timestamp default current_timestamp,
    total_amount numeric(10,2) default 0
);

CREATE TABLE IF NOT EXISTS order_items (
    order_item_id serial primary key,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int not null,
    price numeric(10,2) not null
);

CREATE TABLE IF NOT EXISTS order_log (
    log_id serial primary key,
    order_id int,
    customer_id int,
    action varchar(50),
    log_date timestamp default current_timestamp
);

CREATE OR REPLACE FUNCTION calculate_order_total(p_order_id int)
RETURNS numeric(10,2) AS $$
DECLARE
    v_total numeric(10,2);
BEGIN
    SELECT COALESCE(SUM(quantity * price), 0) INTO v_total
    FROM order_items
    WHERE order_id = p_order_id;
    
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;


--TASK 2
CREATE OR REPLACE PROCEDURE create_order(p_customer_id int)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Customer with ID % does not exist', p_customer_id;
    END IF;

    INSERT INTO orders (customer_id, order_date, total_amount)
    VALUES (p_customer_id, current_timestamp, 0);
END;
$$;

--TASK 3:
CREATE OR REPLACE PROCEDURE add_product_to_order(
    p_order_id int,
    p_product_id int,
    p_quantity int
)
LANGUAGE plpgsql AS $$
DECLARE
    v_price numeric(10,2);
    v_stock int;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero';
    END IF;
    SELECT price, stock_quantity INTO v_price, v_stock
    FROM products WHERE product_id = p_product_id;

    IF v_price IS NULL THEN
        RAISE EXCEPTION 'Product with ID % does not exist', p_product_id;
    END IF;

    IF v_stock < p_quantity THEN
        RAISE EXCEPTION 'Not enough stock for product %. Available: %, Requested: %', p_product_id, v_stock, p_quantity;
    END IF;

    UPDATE products 
    SET stock_quantity = stock_quantity - p_quantity 
    WHERE product_id = p_product_id;

    INSERT INTO order_items (order_id, product_id, quantity, price)
    VALUES (p_order_id, p_product_id, p_quantity, v_price);
END;
$$;

--TASK 4:
CREATE OR REPLACE FUNCTION trg_update_order_total()
RETURNS TRIGGER AS $$
DECLARE
    v_order_id int;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_order_id := OLD.order_id;
    ELSE
        v_order_id := NEW.order_id;
    END IF;

    UPDATE orders
    SET total_amount = calculate_order_total(v_order_id)
    WHERE order_id = v_order_id;

    IF TG_OP = 'DELETE' THEN 
        RETURN OLD; 
    ELSE 
        RETURN NEW; 
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_total
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW EXECUTE FUNCTION trg_update_order_total();

--TASK 5:
CREATE OR REPLACE FUNCTION trg_order_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO order_log (order_id, customer_id, action, log_date)
    VALUES (NEW.order_id, NEW.customer_id, 'ORDER_CREATED', current_timestamp);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_order_audit_log
AFTER INSERT ON orders
FOR EACH ROW EXECUTE FUNCTION trg_order_audit_log();
