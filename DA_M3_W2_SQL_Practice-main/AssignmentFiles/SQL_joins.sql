USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.
SELECT
    p.product_name,
    c.category_name,
    p.price
FROM
    products AS p
INNER JOIN
    categories AS c ON p.category_id = c.category_id;
-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.
SELECT
    o.order_id,
    o.order_datetime,
    s.store_name,
    p.product_name,
    oi.quantity,
    (oi.quantity * p.price) AS line_total
FROM
    order_items oi
-- Joins the order_items table with the orders table on the order_id.
INNER JOIN
    orders o ON oi.order_id = o.order_id
-- Joins the orders table with the stores table on the store_id.
INNER JOIN
    stores s ON o.store_id = s.store_id
-- Joins the order_items table with the products table on the product_id.
INNER JOIN
    products p ON oi.product_id = p.product_id
ORDER BY
    o.order_datetime,
    o.order_id;


-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).
SELECT
    c.customer_name,
    s.store_name,
    o.order_datetime,
    SUM(od.quantity * p.price) AS order_total
FROM
    Customers AS c
INNER JOIN
    Orders AS o
    ON c.customer_id = o.customer_id
INNER JOIN
    Stores AS s
    ON o.store_id = s.store_id
INNER JOIN
    OrderDetails AS od
    ON o.order_id = od.order_id
INNER JOIN
    Products AS p
    ON od.product_id = p.product_id
WHERE
    o.status = 'PAID'  -- Filter for 'PAID' orders
GROUP BY
    c.customer_name,
    s.store_name,
    o.order_datetime,
    o.order_id
ORDER BY
    o.order_datetime DESC;

-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.
SELECT
    c.first_name,
    c.last_name,
    c.city,
    c.state
FROM
    Customers AS c
LEFT JOIN
    Orders AS o ON c.customer_id = o.customer_id
WHERE
    o.order_id IS NULL;
-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.
WITH StoreProductSales AS (
  -- First, calculate total units sold for each product per store,
  -- but only for paid sales.
  SELECT
    s.store_name,
    p.product_name,
    SUM(tr.total_units) AS total_units
  FROM
    transactions tr
  JOIN
    stores s ON tr.store_id = s.store_id
  JOIN
    products p ON tr.product_id = p.product_id
  WHERE
    tr.status = 'PAID'
  GROUP BY
    s.store_name,
    p.product_name
),
RankedSales AS (
  -- Next, rank the products by total units within each store.
  SELECT
    store_name,
    product_name,
    total_units,
    ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY total_units DESC) AS rn
  FROM
    StoreProductSales
)
-- Finally, select the product with rank 1 for each store.
SELECT
  store_name,
  product_name,
  total_units
FROM
  RankedSales
WHERE
  rn = 1;

-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
SELECT
  s.store_name,
  p.product_name,
  i.on_hand
FROM
  inventory AS i
JOIN
  stores AS s
  ON i.store_id = s.store_id
JOIN
  products AS p
  ON i.product_id = p.product_id
WHERE
  i.on_hand < 12;

-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').
SELECT
  s.store_name,
  e.employee_name AS manager_name,
  e.hire_date
FROM
  Stores AS s
INNER JOIN
  Employees AS e
ON
  s.manager_id = e.employee_id;
-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.
WITH ProductPaidRevenue AS (
    SELECT
        p.product_name,
        SUM(od.quantity * od.price_per_unit) AS total_revenue
    FROM
        products p
    JOIN
        order_details od ON p.product_id = od.product_id
    WHERE
        od.payment_status = 'PAID' -- Assuming a 'payment_status' column in order_details
    GROUP BY
        p.product_name
),
AveragePaidRevenue AS (
    SELECT
        AVG(total_revenue) AS avg_paid_revenue
    FROM
        ProductPaidRevenue
)
SELECT
    pr.product_name,
    pr.total_revenue
FROM
    ProductPaidRevenue pr, AveragePaidRevenue apr
WHERE
    pr.total_revenue > apr.avg_paid_revenue;
-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.
SELECT
  c.customer_name,
  last_paid_order.last_paid_order_date
FROM Customers AS c
LEFT JOIN (
  SELECT
    customer_id,
    MAX(order_date) AS last_paid_order_date
  FROM Orders
  WHERE
    status = 'PAID'
  GROUP BY
    customer_id
) AS last_paid_order
  ON c.customer_id = last_paid_order.customer_id;

-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
SELECT
    s.store_id,
    p.category,
    SUM(s.quantity) AS total_units,
    SUM(s.quantity * p.price) AS total_revenue
FROM
    sales s
JOIN
    products p ON s.product_id = p.product_id
WHERE
    s.paid_status = 'PAID' -- Filter for only paid transactions
GROUP BY
    s.store_id,
    p.category
ORDER BY
    s.store_id,
    p.category;
