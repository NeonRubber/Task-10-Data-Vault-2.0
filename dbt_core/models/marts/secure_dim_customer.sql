{{ config(
    materialized='view',
    secure=true,
    tags=['marts', 'security'] 
) }}

SELECT * FROM {{ ref('dim_customer') }}
WHERE 
    CURRENT_ROLE() = 'ACCOUNTADMIN'
    OR c_mktsegment = 'AUTOMOBILE'