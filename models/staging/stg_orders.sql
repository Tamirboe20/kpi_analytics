{{ config(
    materialized='view',
    tags=["staging"]
) }}

SELECT
  order_id,
  user_id,
  created_at,
  status
FROM {{ source('thelook_ecommerce', 'orders') }}
