# Online Store Database System

## Description
This repository contains a PostgreSQL database schema and procedural logic for managing orders in an online store. It was created as part of Practice Assignment 3. 

## Features
- **Data Schema:** Tables for customers, products, orders, order items, and audit logs.
- **SQL Functions:** `calculate_order_total` for dynamic aggregation.
- **Stored Procedures:** `create_order` and `add_product_to_order` to safely handle business logic and decrement stock.
- **Triggers:** Automatic recalculation of order totals upon item updates, and automatic creation of audit logs when new orders are placed.

## Usage
1. Run `schema_and_logic.sql` to initialize the database structure and logic.
2. Run `test_script.sql` to populate initial data and verify that triggers and procedures function correctly.

## Theory
# Theory Questions Answers

**1. What is the difference between a function and a procedure in PostgreSQL?**
Functions must always return a value and are typically used within `SELECT` statements or assignments. Procedures do not require a return value, are invoked using the `CALL` statement, and importantly, they can manage transactions internally (using `COMMIT` and `ROLLBACK`).

**2. Can a trigger be executed manually? Why or why not?**
No, a trigger cannot be executed manually. Triggers are designed to be fired automatically by the database engine as a direct response to specific data modification events (`INSERT`, `UPDATE`, `DELETE`, or `TRUNCATE`) happening on a designated table or view.

**3. What are the advantages and disadvantages of storing business logic inside the database?**
*Advantages:* It centralizes the logic so all connected applications follow the exact same rules, reduces network latency since logic executes close to the data, and ensures high performance for complex data manipulations. 
*Disadvantages:* It makes version control and automated testing more difficult, tightly couples the system to a specific database vendor (e.g., PostgreSQL), and can be harder to debug compared to logic in modern application backends.

## Bonus task 3
```
explain analyze
select
    oi.order_id,
    p.product_name,
    oi.quantity,
    oi.price,
    oi.quantity * oi.price as item_total
from order_items oi
join products p on oi.product_id = p.product_id
where oi.order_id = 1;
