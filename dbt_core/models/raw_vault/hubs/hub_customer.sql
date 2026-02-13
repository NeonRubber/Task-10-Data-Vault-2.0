{{ config(
    materialized='incremental',
    unique_key='hk_customer',
    incremental_strategy='append'
) }}

WITH stg AS (
    SELECT DISTINCT
        hk_customer,
        c_custkey,
        load_dt,
        record_source
    FROM {{ ref('stg_customer') }}
)

SELECT
    src.hk_customer,
    src.c_custkey,
    src.load_dt,
    src.record_source
FROM stg src
{% if is_incremental() %}
LEFT JOIN {{ this }} tgt 
    ON src.hk_customer = tgt.hk_customer
WHERE tgt.hk_customer IS NULL
{% endif %}
