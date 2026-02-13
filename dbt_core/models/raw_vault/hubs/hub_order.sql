{{ config(
    materialized='incremental',
    unique_key='hk_order',
    incremental_strategy='append'
) }}

WITH stg AS (
    SELECT DISTINCT
        hk_order,
        o_orderkey,
        load_dt,
        record_source
    FROM {{ ref('stg_orders') }}
)

SELECT
    src.hk_order,
    src.o_orderkey,
    src.load_dt,
    src.record_source
FROM stg src
{% if is_incremental() %}
LEFT JOIN {{ this }} tgt 
    ON src.hk_order = tgt.hk_order
WHERE tgt.hk_order IS NULL
{% endif %}
