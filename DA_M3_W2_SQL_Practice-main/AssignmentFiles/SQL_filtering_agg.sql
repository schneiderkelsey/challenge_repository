-- ==================================
-- FILTERS & AGGREGATION
-- ==================================

USE coffeeshop_db;


-- Q1) Compute total items per order.
--     Return (order_id, total_items) from order_items.
SELECT
  order_id,
  COUNT(*) AS total_items
FROM
  order_items
GROUP BY
  order_id;

-- Q2) Compute total items per order for PAID orders only.
--     Return (order_id, total_items). Hint: order_id IN (SELECT ... FROM orders WHERE status='paid').
SELECT
    oi.order_id,
    SUM(oi.quantity) AS total_items
FROM
    order_items oi
JOIN
    orders o ON oi.order_id = o.order_id
WHERE
    o.status = 'paid'
GROUP BY
    oi.order_id;
-- Q3) How many orders were placed per day (all statuses)?
--     Return (order_date, orders_count) from orders.
SELECT
  order_date,
  COUNT(order_id) AS orders_count
FROM
  orders
GROUP BY
  order_date
ORDER BY
  order_date;
-- Q4) What is the average number of items per PAID order?
--     Use a subquery or CTE over order_items filtered by order_id IN (...).
WITH PaidOrderItems AS (
    SELECT
        oi.order_id,
        COUNT(oi.item_id) AS item_count
    FROM
        order_items oi
    JOIN
        orders o ON oi.order_id = o.order_id
    WHERE
        o.status = 'PAID' -- Assuming 'PAID' is the status for paid orders
    GROUP BY
        oi.order_id
)
SELECT
    AVG(item_count) AS average_items_per_paid_order
FROM
    PaidOrderItems;
-- Q5) Which products (by product_id) have sold the most units overall across all stores?
--     Return (product_id, total_units), sorted desc.
SELECT
    product_id,
    SUM(quantity) AS total_units
FROM
    sales  -- Assuming 'sales' is the table containing sales information
GROUP BY
    product_id
ORDER BY
    total_units DESC;
-- Q6) Among PAID orders only, which product_ids have the most units sold?
--     Return (product_id, total_units_paid), sorted desc.
--     Hint: order_id IN (SELECT order_id FROM orders WHERE status='paid').
SELECT
  product_id,
  SUM(units) AS total_units_paid
FROM
  order_items
WHERE
  order_id IN (
    SELECT
      order_id
    FROM
      orders
    WHERE
      status = 'paid'
  )
GROUP BY
  product_id
ORDER BY
  total_units_paid DESC;
-- Q7) For each store, how many UNIQUE customers have placed a PAID order?
--     Return (store_id, unique_customers) using only the orders table.
SELECT
    store_id,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM
    orders
WHERE
    order_status = 'PAID' -- Assuming 'PAID' is the status for a paid order
GROUP BY
    store_id;
-- Q8) Which day of week has the highest number of PAID orders?
--     Return (day_name, orders_count). Hint: DAYNAME(order_datetime). Return ties if any.
SELECT 
    DAYNAME(order_datetime) AS day_name,
    COUNT(*) AS orders_count
FROM 
    orders
WHERE 
    status = 'PAID'
GROUP BY 
    day_name
HAVING 
    COUNT(*) = (
        SELECT 
            MAX(day_count)
        FROM (
            SELECT 
                COUNT(*) AS day_count
            FROM 
                orders
            WHERE 
                status = 'PAID'
            GROUP BY 
                DAYNAME(order_datetime)
        ) AS subquery_max
    );

-- Q9) Show the calendar days whose total orders (any status) exceed 3.
--     Use HAVING. Return (order_date, orders_count).
SELECT
  order_date,
  COUNT(order_id) AS orders_count
FROM orders
GROUP BY
  order_date
HAVING
  COUNT(order_id) > 3;

-- Q10) Per store, list payment_method and the number of PAID orders.
--      Return (store_id, payment_method, paid_orders_count).
SELECT
  o.store_id,
  p.payment_method,
  COUNT(o.order_id) AS paid_orders_count
FROM
  orders AS o
JOIN
  payments AS p ON o.order_id = p.order_id
WHERE
  o.order_status = 'PAID'
GROUP BY
  o.store_id,
  p.payment_method
ORDER BY
  o.store_id,
  paid_orders_count DESC;

-- Q11) Among PAID orders, what percent used 'app' as the payment_method?
--      Return a single row with pct_app_paid_orders (0–100).
SELECT
  -- Calculate the percentage of 'app' payments among paid orders.
  -- Multiplying by 100.0 ensures a floating-point division.
  (COUNT(CASE WHEN payment_method = 'app' THEN 1 END) * 100.0) / COUNT(*) AS pct_app_paid_orders
FROM
  orders
-- Filter the orders to include only those with a 'PAID' status.
WHERE
  status = 'PAID';

-- Q12) Busiest hour: for PAID orders, show (hour_of_day, orders_count) sorted desc.
SELECT
  EXTRACT(HOUR FROM order_datetime) AS hour_of_day,
  COUNT(*) AS orders_count
FROM orders
WHERE status = 'PAID'
GROUP BY
  hour_of_day
ORDER BY
  orders_count DESC;


-- ================
