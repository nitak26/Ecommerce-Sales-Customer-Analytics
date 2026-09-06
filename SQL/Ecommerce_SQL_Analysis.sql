-- ============================================================
-- E-COMMERCE SALES & CUSTOMER ANALYTICS
-- SQL Portfolio Analysis | MySQL 8+
-- ============================================================
-- Database: ecommerce
-- Tables used:
--   customers, products, orders, order_items, payments
--
-- Note:
-- Revenue in this script is calculated as quantity * unit_price.
-- Unless explicitly filtered, it includes order items for all order statuses.
-- ============================================================

USE ecommerce;

-- ============================================================
-- SECTION 1: CORE KPI ANALYSIS
-- ============================================================

-- 1. Total Revenue
-- Business Question:
-- What is the total revenue generated from all order items?
SELECT
    SUM(quantity * unit_price) AS total_revenue
FROM order_items;


-- 2. Total Orders
-- Business Question:
-- How many unique orders are present in the dataset?
SELECT
    COUNT(DISTINCT order_id) AS total_orders
FROM orders;


-- 3. Total Customers
-- Business Question:
-- How many unique customers are registered?
SELECT
    COUNT(DISTINCT customer_id) AS total_customers
FROM customers;


-- 4. Average Order Value
-- Business Question:
-- What is the average revenue generated per order?
SELECT
    AVG(order_total) AS average_order_value
FROM (
    SELECT
        order_id,
        SUM(quantity * unit_price) AS order_total
    FROM order_items
    GROUP BY order_id
) AS order_summary;


-- 5. Minimum, Maximum and Average Product Price
-- Business Question:
-- What is the overall product price range?
SELECT
    MIN(price) AS minimum_price,
    MAX(price) AS maximum_price,
    AVG(price) AS average_price
FROM products;


-- ============================================================
-- SECTION 2: CUSTOMER ANALYSIS
-- ============================================================

-- 6. Customers by Gender
-- Business Question:
-- How is the customer base distributed by gender?
SELECT
    gender,
    COUNT(DISTINCT customer_id) AS customer_count
FROM customers
GROUP BY gender
ORDER BY customer_count DESC;


-- 7. Customers by Age Group
-- Business Question:
-- Which age groups contain the highest number of customers?
SELECT
    CASE
        WHEN age < 20 THEN 'Below 20'
        WHEN age BETWEEN 20 AND 30 THEN '20-30'
        WHEN age BETWEEN 31 AND 45 THEN '31-45'
        WHEN age BETWEEN 46 AND 56 THEN '46-56'
        ELSE '57+'
    END AS age_group,
    COUNT(DISTINCT customer_id) AS customer_count
FROM customers
GROUP BY age_group
ORDER BY
    CASE age_group
        WHEN 'Below 20' THEN 1
        WHEN '20-30' THEN 2
        WHEN '31-45' THEN 3
        WHEN '46-56' THEN 4
        ELSE 5
    END;


-- 8. Top 10 Customers by Spending
-- Business Question:
-- Which 10 customers generated the highest revenue?
SELECT
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.quantity * oi.unit_price) AS customer_spending
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_id,
    c.customer_name
ORDER BY
    customer_spending DESC
LIMIT 10;


-- 9. Customers with More Than 3 Orders
-- Business Question:
-- Which customers have placed more than three orders?
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS order_count
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.customer_name
HAVING COUNT(DISTINCT o.order_id) > 3
ORDER BY order_count DESC;


-- 10. Customers Who Never Ordered
-- Business Question:
-- Which registered customers have never placed an order?
SELECT
    c.customer_id,
    c.customer_name
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_name;


-- 11. First and Latest Order Date per Customer
-- Business Question:
-- When did each customer first and most recently place an order?
SELECT
    c.customer_id,
    c.customer_name,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS latest_order_date
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.customer_name
ORDER BY first_order_date;


-- 12. Rank Customers by Spending
-- Business Question:
-- How do customers rank based on total spending?
WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * oi.unit_price) AS total_spending
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        c.customer_id,
        c.customer_name
)
SELECT
    customer_id,
    customer_name,
    total_spending,
    RANK() OVER (ORDER BY total_spending DESC) AS spending_rank
FROM customer_spend
ORDER BY spending_rank;


-- 13. Customers Spending Above Average
-- Business Question:
-- Which customers spend more than the average customer?
WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * oi.unit_price) AS total_spending
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        c.customer_id,
        c.customer_name
)
SELECT
    customer_id,
    customer_name,
    total_spending
FROM customer_spend
WHERE total_spending > (
    SELECT AVG(total_spending)
    FROM customer_spend
)
ORDER BY total_spending DESC;


-- ============================================================
-- SECTION 3: PRODUCT & CATEGORY ANALYSIS
-- ============================================================

-- 14. Revenue by Product Category
-- Business Question:
-- Which product categories generate the most revenue?
SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;


-- 15. Total Quantity Sold per Product
-- Business Question:
-- How many units of each product were sold?
SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.product_name
ORDER BY total_quantity_sold DESC;


-- 16. Top 10 Best-Selling Products
-- Business Question:
-- Which products sold the highest number of units?
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity) AS total_quantity_sold
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category
ORDER BY total_quantity_sold DESC
LIMIT 10;


-- 17. Highest-Revenue Product in Each Category
-- Business Question:
-- Which product generates the most revenue within each category?
WITH product_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        p.category,
        p.product_id,
        p.product_name
),
ranked_products AS (
    SELECT
        category,
        product_id,
        product_name,
        revenue,
        RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS revenue_rank
    FROM product_revenue
)
SELECT
    category,
    product_id,
    product_name,
    revenue
FROM ranked_products
WHERE revenue_rank = 1
ORDER BY revenue DESC;


-- 18. Top 3 Products per Category by Revenue
-- Business Question:
-- What are the top three revenue-generating products in each category?
WITH product_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        p.category,
        p.product_id,
        p.product_name
),
ranked_products AS (
    SELECT
        category,
        product_id,
        product_name,
        revenue,
        RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS revenue_rank
    FROM product_revenue
)
SELECT
    category,
    product_id,
    product_name,
    revenue,
    revenue_rank
FROM ranked_products
WHERE revenue_rank <= 3
ORDER BY category, revenue_rank;


-- 19. Categories Above a Revenue Threshold
-- Business Question:
-- Which categories generate more than ₹1,000,000 in revenue?
SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.category
HAVING SUM(oi.quantity * oi.unit_price) > 1000000
ORDER BY revenue DESC;


-- ============================================================
-- SECTION 4: ORDER & PAYMENT ANALYSIS
-- ============================================================

-- 20. Orders by Status
-- Business Question:
-- How are orders distributed across different statuses?
SELECT
    order_status,
    COUNT(DISTINCT order_id) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- 21. Cancelled Order Percentage
-- Business Question:
-- What percentage of all orders were cancelled?
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS cancellation_percentage
FROM orders;


-- 22. Most Popular Payment Method
-- Business Question:
-- Which payment method is used most frequently?
SELECT
    payment_method,
    COUNT(DISTINCT payment_id) AS payment_count
FROM payments
GROUP BY payment_method
ORDER BY payment_count DESC;


-- 23. Revenue by Payment Method
-- Business Question:
-- How much payment value is associated with each payment method?
SELECT
    payment_method,
    SUM(amount) AS total_payment_amount
FROM payments
GROUP BY payment_method
ORDER BY total_payment_amount DESC;


-- 24. Revenue by Shipping State
-- Business Question:
-- Which shipping states generate the highest revenue?
SELECT
    o.shipping_state,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.shipping_state
ORDER BY revenue DESC;


-- 25. State with Highest Average Order Value
-- Business Question:
-- Which shipping state has the highest average order value?
WITH order_totals AS (
    SELECT
        o.order_id,
        o.shipping_state,
        SUM(oi.quantity * oi.unit_price) AS order_total
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        o.shipping_state
)
SELECT
    shipping_state,
    AVG(order_total) AS average_order_value
FROM order_totals
GROUP BY shipping_state
ORDER BY average_order_value DESC
LIMIT 1;


-- ============================================================
-- SECTION 5: TIME-SERIES & ADVANCED ANALYSIS
-- ============================================================

-- 26. Monthly Revenue Trend
-- Business Question:
-- How has revenue changed month by month?
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
    SUM(oi.quantity * oi.unit_price) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY year_month;


-- 27. Monthly Revenue for 2024
-- Business Question:
-- What was monthly revenue during 2024?
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
    SUM(oi.quantity * oi.unit_price) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE YEAR(o.order_date) = 2024
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY year_month;


-- 28. Month-over-Month Revenue Change
-- Business Question:
-- How much did revenue increase or decrease compared with the previous month?
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    year_month,
    revenue,
    LAG(revenue) OVER (ORDER BY year_month) AS previous_month_revenue,
    revenue - LAG(revenue) OVER (ORDER BY year_month) AS revenue_change
FROM monthly_revenue
ORDER BY year_month;


-- 29. Month-over-Month Revenue Growth %
-- Business Question:
-- What is the monthly percentage growth or decline in revenue?
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
revenue_with_previous AS (
    SELECT
        year_month,
        revenue,
        LAG(revenue) OVER (ORDER BY year_month) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    year_month,
    revenue,
    previous_month_revenue,
    ROUND(
        100.0 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS mom_growth_percentage
FROM revenue_with_previous
ORDER BY year_month;


-- 30. Cumulative Monthly Revenue
-- Business Question:
-- How does cumulative revenue grow over time?
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    year_month,
    revenue,
    SUM(revenue) OVER (
        ORDER BY year_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM monthly_revenue
ORDER BY year_month;


-- ============================================================
-- END OF ANALYSIS
-- ============================================================
