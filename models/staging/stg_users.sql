{{ config(
    materialized='view',
    tags=["staging"]
) }}

SELECT
  id           AS user_id,
  first_name,
  last_name,
  gender,
  email,
  age,
  created_at
FROM {{ source('thelook_ecommerce', 'users') }}
WHERE created_at IS NOT NULL
