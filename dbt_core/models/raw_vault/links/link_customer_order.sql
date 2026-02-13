{{ config(
    materialized='incremental',
    unique_key='hk_order_customer',
    incremental_strategy='append'
) }}

WITH stg AS (
    SELECT DISTINCT
        hk_order_customer,
        hk_order,
        hk_customer,
        o_orderkey,
        o_custkey,
        load_dt,
        record_source
    FROM {{ ref('stg_orders') }}
)

SELECT
    src.hk_order_customer,
    src.hk_order,
    src.hk_customer,
    src.o_orderkey,
    src.o_custkey,
    src.load_dt,
    src.record_source
FROM stg src
{% if is_incremental() %}
LEFT JOIN {{ this }} tgt 
    ON src.hk_order_customer = tgt.hk_order_customer
WHERE tgt.hk_order_customer IS NULL
{% endif %}
