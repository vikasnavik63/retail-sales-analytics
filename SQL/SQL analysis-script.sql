CREATE DATABASE retail_analytics;
USE retail_analytics;

SELECT DATABASE();

CREATE TABLE customers (
    Customer_ID INT PRIMARY KEY,
    Customer_Name VARCHAR(100),
    Email VARCHAR(255),
    Gender VARCHAR(20),
    Age INT,
    Country VARCHAR(100),
    City VARCHAR(100),
    Customer_Segment VARCHAR(50)
);

CREATE TABLE products (
    Product_ID INT AUTO_INCREMENT PRIMARY KEY,
    Product_Name VARCHAR(255) NOT NULL,
    Product_Category VARCHAR(100) NOT NULL,
    UNIQUE KEY unique_product (Product_Name, Product_Category)
);

CREATE TABLE orders (
    Order_Line_ID INT AUTO_INCREMENT PRIMARY KEY,
    Order_ID VARCHAR(50) NOT NULL,
    Order_Date DATE NOT NULL,
    Ship_Date DATE NOT NULL,
    Customer_ID INT NOT NULL,
    Product_ID INT NOT NULL,
    Quantity INT NOT NULL,
    Unit_Price DECIMAL(12,2) NOT NULL,
    Discount_Percent DECIMAL(5,2),
    Shipping_Cost DECIMAL(12,2),
    Payment_Method VARCHAR(50),
    Sales_Channel VARCHAR(50),
    Order_Status VARCHAR(50),
    Negative_Quantity_Flag BOOLEAN,

    FOREIGN KEY (Customer_ID) REFERENCES customers(Customer_ID),
    FOREIGN KEY (Product_ID) REFERENCES products(Product_ID)
);

USE retail_analytics;

CREATE TABLE retail_staging (
    Order_ID VARCHAR(50),
    Order_Date DATE,
    Ship_Date DATE,
    Customer_ID INT,
    Customer_Name VARCHAR(100),
    Email VARCHAR(255),
    Gender VARCHAR(20),
    Age INT,
    Country VARCHAR(100),
    City VARCHAR(100),
    Customer_Segment VARCHAR(50),
    Product_Category VARCHAR(100),
    Product_Name VARCHAR(255),
    Quantity INT,
    Unit_Price DECIMAL(12,2),
    Discount_Percent DECIMAL(5,2),
    Shipping_Cost DECIMAL(12,2),
    Payment_Method VARCHAR(50),
    Sales_Channel VARCHAR(50),
    Order_Status VARCHAR(50),
    Quantity_Type VARCHAR(50),
    Negative_Quantity_Flag BOOLEAN
);

LOAD DATA LOCAL INFILE 'C:/Users/vikas/OneDrive/Desktop/Retail-Analytics-Project/cleaned_data/retail_sales_clean.csv'
INTO TABLE retail_staging
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    Order_ID,
    Order_Date,
    Ship_Date,
    Customer_ID,
    Customer_Name,
    @Email,
    Gender,
    Age,
    Country,
    @City,
    @Customer_Segment,
    Product_Category,
    Product_Name,
    Quantity,
    Unit_Price,
    Discount_Percent,
    Shipping_Cost,
    @Payment_Method,
    Sales_Channel,
    Order_Status,
    Quantity_Type,
    @Negative_Quantity_Flag
)
SET
    Email = NULLIF(@Email, ''),
    City = NULLIF(@City, ''),
    Customer_Segment = NULLIF(@Customer_Segment, ''),
    Payment_Method = NULLIF(@Payment_Method, ''),
    Negative_Quantity_Flag =
        CASE
            WHEN LOWER(@Negative_Quantity_Flag) = 'true' THEN 'True'
            WHEN LOWER(@Negative_Quantity_Flag) = 'false' THEN 'False'
            ELSE NULL
        END;

SELECT COUNT(*) AS imported_rows
FROM retail_staging;

-- Business analyst que
-- Q1. Total Revenue

SELECT
    ROUND(
        SUM(
            Quantity * Unit_Price *
            (1 - COALESCE(Discount_Percent, 0) / 100)
        ),
        2
    ) AS total_revenue
FROM orders;

-- Q2. Total Number of Orders

SELECT
    COUNT(DISTINCT Order_ID) AS total_orders
FROM orders;

-- Q3. Unique Customers

SELECT
    COUNT(DISTINCT Customer_ID) AS unique_customers
FROM orders;

-- Q4. Total Quantity Sold

SELECT
    SUM(Quantity) AS total_quantity_sold
FROM orders;

-- Q5. Average Order Value

SELECT
    ROUND(
        SUM(
            Quantity * Unit_Price *
            (1 - COALESCE(Discount_Percent, 0) / 100)
        ) / COUNT(DISTINCT Order_ID),
        2
    ) AS average_order_value
FROM orders;

-- Q6. Monthly Revenue Trend

SELECT
    DATE_FORMAT(Order_Date, '%Y-%m') AS month,
    ROUND(
        SUM(
            Quantity * Unit_Price *
            (1 - COALESCE(Discount_Percent, 0) / 100)
        ),
        2
    ) AS monthly_revenue
FROM orders
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY month;

-- Q7. Revenue by Product Category

SELECT
    p.Product_Category,
    ROUND(
        SUM(
            o.Quantity * o.Unit_Price *
            (1 - COALESCE(o.Discount_Percent, 0) / 100)
        ),
        2
    ) AS revenue
FROM orders o
JOIN products p
    ON o.Product_ID = p.Product_ID
GROUP BY p.Product_Category
ORDER BY revenue DESC;

-- Q8. Top 10 Products by Revenue

SELECT
    p.Product_Name,
    p.Product_Category,
    ROUND(
        SUM(
            o.Quantity * o.Unit_Price *
            (1 - COALESCE(o.Discount_Percent, 0) / 100)
        ),
        2
    ) AS revenue
FROM orders o
JOIN products p
    ON o.Product_ID = p.Product_ID
GROUP BY
    p.Product_ID,
    p.Product_Name,
    p.Product_Category
ORDER BY revenue DESC
LIMIT 10;

-- Q9. Revenue by Customer Segment

SELECT
    c.Customer_Segment,
    ROUND(
        SUM(
            o.Quantity * o.Unit_Price *
            (1 - COALESCE(o.Discount_Percent, 0) / 100)
        ),
        2
    ) AS revenue
FROM orders o
JOIN customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY c.Customer_Segment
ORDER BY revenue DESC;

-- Q10. Revenue by Sales Channel

SELECT
    Sales_Channel,
    ROUND(
        SUM(
            Quantity * Unit_Price *
            (1 - COALESCE(Discount_Percent, 0) / 100)
        ),
        2
    ) AS revenue
FROM orders
GROUP BY Sales_Channel
ORDER BY revenue DESC;

-- Q11. Payment Method Usage

SELECT
    Payment_Method,
    COUNT(*) AS order_lines,
    COUNT(DISTINCT Order_ID) AS unique_orders
FROM orders
GROUP BY Payment_Method
ORDER BY unique_orders DESC;

-- Q12. Revenue by Country

SELECT
    c.Country,
    ROUND(
        SUM(
            o.Quantity * o.Unit_Price *
            (1 - COALESCE(o.Discount_Percent, 0) / 100)
        ),
        2
    ) AS revenue
FROM orders o
JOIN customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY c.Country
ORDER BY revenue DESC;

-- Q13. Orders by Status

SELECT
    Order_Status,
    COUNT(DISTINCT Order_ID) AS orders
FROM orders
GROUP BY Order_Status
ORDER BY orders DESC;

-- Q14. Revenue by Order Status

SELECT
    Order_Status,
    ROUND(
        SUM(
            Quantity * Unit_Price *
            (1 - COALESCE(Discount_Percent, 0) / 100)
        ),
        2
    ) AS revenue
FROM orders
GROUP BY Order_Status
ORDER BY revenue DESC;

-- Q15. Negative-Quantity Transactions

SELECT
    COUNT(*) AS negative_quantity_rows
FROM orders
WHERE Quantity < 0;

-- Q16. Products with Negative-Quantity Transactions

SELECT
    p.Product_Name,
    p.Product_Category,
    COUNT(*) AS negative_transactions,
    SUM(o.Quantity) AS net_negative_quantity
FROM orders o
JOIN products p
    ON o.Product_ID = p.Product_ID
WHERE o.Quantity < 0
GROUP BY
    p.Product_ID,
    p.Product_Name,
    p.Product_Category
ORDER BY negative_transactions DESC;

-- Q17. Top 10 Customers by Revenue

SELECT
    c.Customer_ID,
    c.Customer_Name,
    c.Customer_Segment,
    ROUND(
        SUM(
            o.Quantity * o.Unit_Price *
            (1 - COALESCE(o.Discount_Percent, 0) / 100)
        ),
        2
    ) AS customer_revenue
FROM orders o
JOIN customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY
    c.Customer_ID,
    c.Customer_Name,
    c.Customer_Segment
ORDER BY customer_revenue DESC
LIMIT 10;

-- Q18. Average Discount by Product Category

SELECT
    p.Product_Category,
    ROUND(AVG(o.Discount_Percent), 2) AS average_discount
FROM orders o
JOIN products p
    ON o.Product_ID = p.Product_ID
GROUP BY p.Product_Category
ORDER BY average_discount DESC;

-- Q19. Quantity Sold by Product Category

SELECT
    p.Product_Category,
    SUM(o.Quantity) AS total_quantity
FROM orders o
JOIN products p
    ON o.Product_ID = p.Product_ID
GROUP BY p.Product_Category
ORDER BY total_quantity DESC;

-- Q20. Average Shipping Time

SELECT
    ROUND(
        AVG(DATEDIFF(Ship_Date, Order_Date)),
        2
    ) AS average_shipping_days
FROM orders;

-- Q21. Average Shipping Time by Sales Channel

SELECT
    Sales_Channel,
    ROUND(
        AVG(DATEDIFF(Ship_Date, Order_Date)),
        2
    ) AS average_shipping_days
FROM orders
GROUP BY Sales_Channel
ORDER BY average_shipping_days;

-- Q22. Top 10 Customers by Number of Orders
SELECT
    Customer_ID,
    COUNT(DISTINCT Order_ID) AS total_orders
FROM orders
GROUP BY Customer_ID
ORDER BY total_orders DESC
LIMIT 10;

-- Q23. Revenue by Gender
SELECT
    c.Gender,
    ROUND(
        SUM(o.Quantity * o.Unit_Price * (1 - COALESCE(o.Discount_Percent, 0) / 100)),
        2
    ) AS total_revenue
FROM orders o
JOIN customers c
    ON o.Customer_ID = c.Customer_ID
GROUP BY c.Gender
ORDER BY total_revenue DESC;

-- Q24. Revenue by Product Category and Sales Channel
SELECT
    Product_Category,
    Sales_Channel,
    ROUND(
        SUM(
            Quantity * Unit_Price *
            (1 - COALESCE(Discount_Percent, 0) / 100)
        ),
        2
    ) AS total_revenue
FROM orders o
JOIN products p
    ON o.Product_ID = p.Product_ID
GROUP BY
    Product_Category,
    Sales_Channel
ORDER BY
    Product_Category,
    total_revenue DESC;
    
    -- Q25. Monthly Order Volume
SELECT
    DATE_FORMAT(Order_Date, '%Y-%m') AS order_month,
    COUNT(DISTINCT Order_ID) AS total_orders
FROM orders
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY order_month;