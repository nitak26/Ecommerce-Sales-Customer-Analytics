USE ecommerce;

-- Example: Extract April 2024 sales data for the monthly CSV workflow
SELECT
    oi.order_item_id,
    o.order_id,
    o.order_date,
    o.customer_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    p.payment_method,
    o.order_status
FROM orders AS o
INNER JOIN order_items AS oi
    ON o.order_id = oi.order_id
INNER JOIN payments AS p
    ON o.order_id = p.order_id
WHERE o.order_date >= '2024-04-01'
  AND o.order_date <  '2024-05-01'
ORDER BY
    o.order_date,
    o.order_id,
    oi.order_item_id;
