USE online_retail_db;

-- 1. Complete order details
SELECT 
    o.order_id,
    o.order_date,
    o.status AS order_status,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    p.name AS product_name,
    p.category,
    oi.quantity,
    oi.price_per_item,
    (oi.quantity * oi.price_per_item) AS item_total
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN Order_Items oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
ORDER BY o.order_date, o.order_id;

-- 2. Total revenue from completed payments
SELECT 
    SUM(amount) AS total_completed_revenue
FROM Payments
WHERE status = 'Completed';

-- 3. Monthly sales trend
SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * oi.price_per_item) AS monthly_revenue
FROM Orders o
JOIN Order_Items oi ON o.order_id = oi.order_id
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY sales_month;

-- 4. Top 5 customers by spending
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.city,
    SUM(oi.quantity * oi.price_per_item) AS total_spent
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, customer_name, c.city
ORDER BY total_spent DESC
LIMIT 5;

-- 5. Best-selling products by quantity sold
SELECT 
    p.product_id,
    p.name AS product_name,
    p.category,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.quantity * oi.price_per_item) AS total_sales_value
FROM Products p
JOIN Order_Items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.name, p.category
ORDER BY total_quantity_sold DESC;

-- 6. Category-wise revenue
SELECT 
    p.category,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * oi.price_per_item) AS category_revenue
FROM Products p
JOIN Order_Items oi ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;

-- 7. Low-stock products
SELECT 
    product_id,
    name,
    category,
    stock_quantity
FROM Products
WHERE stock_quantity < 25
ORDER BY stock_quantity ASC;

-- 8. Payment-method-wise revenue
SELECT 
    payment_method,
    COUNT(*) AS total_payments,
    SUM(amount) AS total_revenue
FROM Payments
GROUP BY payment_method
ORDER BY total_revenue DESC;

-- 9. Average order value
SELECT 
    ROUND(SUM(oi.quantity * oi.price_per_item) / COUNT(DISTINCT o.order_id), 2) AS average_order_value
FROM Orders o
JOIN Order_Items oi ON o.order_id = oi.order_id;

-- 10. Order status summary
SELECT 
    status,
    COUNT(*) AS total_orders
FROM Orders
GROUP BY status
ORDER BY total_orders DESC;

-- 11. Repeat customers
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(o.order_id) AS number_of_orders
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, customer_name
HAVING COUNT(o.order_id) > 1
ORDER BY number_of_orders DESC;

-- 12. Check current inventory after trigger-based stock updates
SELECT 
    product_id,
    name,
    category,
    stock_quantity
FROM Products
ORDER BY stock_quantity ASC;

-- View 1: Sales summary view
DROP VIEW IF EXISTS v_SalesSummary;
CREATE VIEW v_SalesSummary AS
SELECT 
    o.order_id,
    o.order_date,
    o.status AS order_status,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    p.name AS product_name,
    p.category,
    oi.quantity,
    oi.price_per_item,
    (oi.quantity * oi.price_per_item) AS item_total
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN Order_Items oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id;

SELECT * FROM v_SalesSummary;

-- View 2: Order total view
DROP VIEW IF EXISTS v_OrderTotals;
CREATE VIEW v_OrderTotals AS
SELECT 
    o.order_id,
    o.order_date,
    o.status AS order_status,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(oi.quantity * oi.price_per_item) AS order_total
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_date, o.status, customer_name;

SELECT * FROM v_OrderTotals;

-- Stored procedure 1: Get all orders of a customer using email
DROP PROCEDURE IF EXISTS sp_GetCustomerOrders;
DELIMITER $$
CREATE PROCEDURE sp_GetCustomerOrders(IN p_customer_email VARCHAR(100))
BEGIN
    SELECT 
        o.order_id,
        o.order_date,
        o.status AS order_status,
        SUM(oi.quantity * oi.price_per_item) AS order_total
    FROM Orders o
    JOIN Customers c ON o.customer_id = c.customer_id
    JOIN Order_Items oi ON o.order_id = oi.order_id
    WHERE c.email = p_customer_email
    GROUP BY o.order_id, o.order_date, o.status
    ORDER BY o.order_date;
END$$
DELIMITER ;

CALL sp_GetCustomerOrders('aarav.sharma@example.com');

-- Stored procedure 2: Get monthly sales by year and month
DROP PROCEDURE IF EXISTS sp_GetMonthlySales;
DELIMITER $$
CREATE PROCEDURE sp_GetMonthlySales(IN p_year INT, IN p_month INT)
BEGIN
    SELECT 
        o.order_id,
        o.order_date,
        o.status AS order_status,
        SUM(oi.quantity * oi.price_per_item) AS order_total
    FROM Orders o
    JOIN Order_Items oi ON o.order_id = oi.order_id
    WHERE YEAR(o.order_date) = p_year
      AND MONTH(o.order_date) = p_month
    GROUP BY o.order_id, o.order_date, o.status
    ORDER BY o.order_date;
END$$
DELIMITER ;

CALL sp_GetMonthlySales(2025, 11);
