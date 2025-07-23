{{ config(
    materialized='table',
    tags=["kpi", "monthly", "summary"],
    description="Monthly KPI breakdown with user acquisition, revenue, churn and return/cancel rates"
) }}

WITH
  user_first_signup AS (
    SELECT
      id                             AS user_id,
      EXTRACT(YEAR  FROM created_at) AS year,
      EXTRACT(MONTH FROM created_at) AS month
    FROM bigquery-public-data.thelook_ecommerce.users
    WHERE created_at IS NOT NULL
  ),

  user_first_purchase AS (
    SELECT
      user_id,
      EXTRACT(YEAR  FROM MIN(created_at)) AS year,
      EXTRACT(MONTH FROM MIN(created_at)) AS month
    FROM bigquery-public-data.thelook_ecommerce.orders
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY user_id
  ),

  new_users_by_m AS (
    SELECT 
      year, month, COUNT(*) AS new_users
    FROM user_first_signup
    GROUP BY 1, 2
  ),

  new_purchasing_by_m AS (
    SELECT 
      year, month, COUNT(*) AS new_purchasing_users
    FROM user_first_purchase
    GROUP BY 1, 2
  ),

  sales_by_m AS (
    SELECT
      EXTRACT(YEAR  FROM created_at) AS year,
      EXTRACT(MONTH FROM created_at) AS month,
      COUNT(*)                       AS orders_count
    FROM bigquery-public-data.thelook_ecommerce.orders
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY 1, 2
  ),

  revenue_by_m AS (
    SELECT
      EXTRACT(YEAR  FROM oi.created_at) AS year,
      EXTRACT(MONTH FROM oi.created_at) AS month,
      SUM(oi.sale_price)          AS total_revenue,
      SUM(oi.sale_price - p.cost) AS total_profit
    FROM bigquery-public-data.thelook_ecommerce.order_items AS oi
    JOIN bigquery-public-data.thelook_ecommerce.products    AS p
      ON oi.product_id = p.id
    WHERE oi.status NOT IN ('Cancelled', 'Returned')
    GROUP BY 1, 2
  ),

  returned_by_m AS (
    SELECT
      EXTRACT(YEAR  FROM created_at) AS year,
      EXTRACT(MONTH FROM created_at) AS month,
      COUNT(*)                AS returned_orders,
      COUNT(DISTINCT user_id) AS returned_users
    FROM bigquery-public-data.thelook_ecommerce.orders
    WHERE status = 'Returned'
    GROUP BY 1, 2
  ),

  canceled_by_m AS (
    SELECT
      EXTRACT(YEAR  FROM created_at) AS year,
      EXTRACT(MONTH FROM created_at) AS month,
      COUNT(*)                AS canceled_orders,
      COUNT(DISTINCT user_id) AS canceled_users
    FROM bigquery-public-data.thelook_ecommerce.orders
    WHERE status = 'Cancelled'
    GROUP BY 1, 2
  ),

  churn_by_m AS (
    WITH last_purchase AS (
      SELECT 
        user_id, 
        MAX(created_at) AS last_order_ts
      FROM bigquery-public-data.thelook_ecommerce.orders
      WHERE status NOT IN ('Cancelled', 'Returned')
      GROUP BY user_id
    )
    SELECT
      EXTRACT(YEAR  FROM last_order_ts) AS year,
      EXTRACT(MONTH FROM last_order_ts) AS month,
      COUNT(*) AS churned_users
    FROM last_purchase
    WHERE DATE(last_order_ts) < DATE_SUB(DATE '2025-07-20', INTERVAL 365 DAY)
    GROUP BY 1, 2
  )

SELECT
  q.year,
  EXTRACT(QUARTER FROM DATE(q.year, q.month, 1)) AS quarter,
  q.month,
  FORMAT_DATE('%B', DATE(q.year, q.month, 1))   AS month_name,
  DATE(q.year, q.month, 1)                      AS month_start_date,

  SUM(IFNULL(n.new_users, 0)) OVER(ORDER BY q.year, q.month)  AS total_registered_users,
  SUM(IFNULL(pu.new_purchasing_users, 0)) OVER(ORDER BY q.year, q.month) AS total_purchasing_users,

  IFNULL(n.new_users, 0)             AS new_users,
  IFNULL(pu.new_purchasing_users, 0) AS new_purchasing_users,

  IFNULL(s.orders_count, 0)   AS orders_count,
  IFNULL(r.total_revenue, 0)  AS total_revenue,
  IFNULL(r.total_profit, 0)   AS total_profit,
  IFNULL(ch.churned_users, 0) AS churned_users,
  IFNULL(ret.returned_users, 0)  AS returned_users,
  IFNULL(can.canceled_users, 0)  AS canceled_users,
  ROUND(
    SAFE_DIVIDE(IFNULL(ret.returned_orders, 0),
                IFNULL(s.orders_count, 0) +
                IFNULL(ret.returned_orders, 0) +
                IFNULL(can.canceled_orders, 0)) * 100, 2
  ) AS return_rate,
  ROUND(
    SAFE_DIVIDE(IFNULL(can.canceled_orders, 0),
                IFNULL(s.orders_count, 0) +
                IFNULL(ret.returned_orders, 0) +
                IFNULL(can.canceled_orders, 0)) * 100, 2
  ) AS cancel_rate
FROM (
  SELECT 
    EXTRACT(YEAR  FROM created_at) AS year,
    EXTRACT(MONTH FROM created_at) AS month
  FROM bigquery-public-data.thelook_ecommerce.orders
  UNION DISTINCT
  SELECT 
    EXTRACT(YEAR  FROM created_at) AS year,
    EXTRACT(MONTH FROM created_at) AS month
  FROM bigquery-public-data.thelook_ecommerce.users
) AS q
LEFT JOIN new_users_by_m      AS n   USING(year, month)
LEFT JOIN new_purchasing_by_m AS pu  USING(year, month)
LEFT JOIN sales_by_m          AS s   USING(year, month)
LEFT JOIN revenue_by_m        AS r   USING(year, month)
LEFT JOIN returned_by_m       AS ret USING(year, month)
LEFT JOIN canceled_by_m       AS can USING(year, month)
LEFT JOIN churn_by_m          AS ch  USING(year, month)
ORDER BY q.year, q.month
