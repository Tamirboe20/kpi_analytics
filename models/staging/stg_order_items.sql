{{ config(
    materialized='view',
    tags=["staging"]
) }}

SELECT
  id              AS order_item_id,
  order_id,
  product_id,
  user_id,
  status,
  created_at,
  sale_price
FROM {{ source('thelook_ecommerce', 'order_items') }}
WHERE created_at IS NOT NULL
