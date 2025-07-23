{{ config(
    materialized='view',
    tags=["staging"]
) }}

SELECT
  id           AS product_id,
  name,
  category,
  cost,
  brand
FROM {{ source('thelook_ecommerce', 'products') }}
