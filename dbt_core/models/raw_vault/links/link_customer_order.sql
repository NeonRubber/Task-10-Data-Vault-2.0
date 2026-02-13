{{ config(materialized='incremental') }}

SELECT DISTINCT
    t1.hk_order_customer,
    t1.hk_customer,
    t1.hk_order,
    t1.load_dt,
    t1.record_source

FROM {{ ref('stg_orders') }} t1

{% if is_incremental() %}
    LEFT JOIN {{ this }} t2 
    ON t1.hk_order_customer = t2.hk_order_customer
    WHERE t2.hk_order_customer IS NULL
{% endif %}