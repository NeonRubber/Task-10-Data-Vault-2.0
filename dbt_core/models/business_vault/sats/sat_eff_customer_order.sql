{{
    config(
        materialized='incremental',
        unique_key=['hk_order_customer', 'load_dt'],
        incremental_strategy='merge'
    )
}}

WITH source_data AS (
    SELECT DISTINCT
        hk_order_customer,
        load_dt,
        record_source
    FROM {{ ref('link_customer_order') }}
    {% if is_incremental() %}
    WHERE load_dt > (SELECT MAX(load_dt) FROM {{ this }})
    {% endif %}
),

active_records AS (
    {% if is_incremental() %}
    SELECT
        hk_order_customer,
        load_dt,
        record_source
    FROM {{ this }}
    WHERE is_active = TRUE
    {% else %}
    SELECT 
        NULL::BINARY(32) as hk_order_customer, 
        NULL::TIMESTAMP as load_dt, 
        NULL::VARCHAR as record_source 
    WHERE 1=0
    {% endif %}
),

combined_data AS (
    SELECT * FROM source_data
    UNION 
    SELECT * FROM active_records
),

calc_eff AS (
    SELECT
        hk_order_customer,
        load_dt,
        record_source,
        load_dt AS effective_from,
        LEAD(load_dt) OVER (PARTITION BY hk_order_customer ORDER BY load_dt) AS effective_to
    FROM combined_data
)

SELECT
    hk_order_customer,
    load_dt,
    record_source,
    effective_from,
    COALESCE(effective_to, TO_TIMESTAMP('9999-12-31')) as effective_to,
    CASE 
        WHEN effective_to IS NULL THEN TRUE 
        ELSE FALSE 
    END AS is_active
FROM calc_eff