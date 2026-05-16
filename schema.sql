-- Create database
DROP DATABASE IF EXISTS online_retail_db;
CREATE DATABASE online_retail_db DEFAULT CHARACTER SET utf8mb4;
USE online_retail_db;

-- Customers table
CREATE TABLE Customers (
    customer_id INT NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    city VARCHAR(100),
    state VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id),
    UNIQUE KEY email_unique (email)
) ENGINE = InnoDB;

-- Products table
CREATE TABLE Products (
    product_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    PRIMARY KEY (product_id),
    CHECK (price >= 0),
    CHECK (stock_quantity >= 0)
) ENGINE = InnoDB;

-- Orders table
CREATE TABLE Orders (
    order_id INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'Pending',
    PRIMARY KEY (order_id),
    INDEX idx_orders_customer_id (customer_id),
    INDEX idx_orders_order_date (order_date),
    CONSTRAINT fk_orders_customers
        FOREIGN KEY (customer_id)
        REFERENCES Customers(customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CHECK (status IN ('Pending', 'Shipped', 'Delivered', 'Cancelled'))
) ENGINE = InnoDB;

-- Order items table
CREATE TABLE Order_Items (
    order_item_id INT NOT NULL AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price_per_item DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_item_id),
    INDEX idx_order_items_order_id (order_id),
    INDEX idx_order_items_product_id (product_id),
    CONSTRAINT fk_order_items_orders
        FOREIGN KEY (order_id)
        REFERENCES Orders(order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_products
        FOREIGN KEY (product_id)
        REFERENCES Products(product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CHECK (quantity > 0),
    CHECK (price_per_item >= 0)
) ENGINE = InnoDB;

-- Payments table
CREATE TABLE Payments (
    payment_id INT NOT NULL AUTO_INCREMENT,
    order_id INT NOT NULL,
    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'Completed',
    PRIMARY KEY (payment_id),
    INDEX idx_payments_order_id (order_id),
    CONSTRAINT fk_payments_orders
        FOREIGN KEY (order_id)
        REFERENCES Orders(order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CHECK (amount >= 0),
    CHECK (status IN ('Completed', 'Pending', 'Failed', 'Refunded'))
) ENGINE = InnoDB;

-- Trigger 1: Validate stock before inserting order items
DELIMITER $$

CREATE TRIGGER tr_CheckStockBeforeOrderItemInsert
BEFORE INSERT ON Order_Items
FOR EACH ROW
BEGIN
    DECLARE available_stock INT;

    SELECT stock_quantity
    INTO available_stock
    FROM Products
    WHERE product_id = NEW.product_id;

    IF available_stock IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product does not exist';
    END IF;

    IF available_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock for this product';
    END IF;
END$$

DELIMITER ;

-- Trigger 2: Reduce stock after inserting order items
DELIMITER $$

CREATE TRIGGER tr_UpdateStockAfterOrderItemInsert
AFTER INSERT ON Order_Items
FOR EACH ROW
BEGIN
    UPDATE Products
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
END$$

DELIMITER ;
