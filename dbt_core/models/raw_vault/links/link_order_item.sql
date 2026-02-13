{{ config(
    materialized='incremental',
    unique_key='hk_order_part',
    incremental_strategy='append'
) }}

WITH stg AS (
    SELECT DISTINCT
        hk_order_part,
        hk_order,
        hk_part,
        load_dt,
        record_source
    FROM {{ ref('stg_lineitem') }}
)

SELECT
    src.hk_order_part,
    src.hk_order,
    src.hk_part,
    src.load_dt,
    src.record_source
FROM stg src
{% if is_incremental() %}
LEFT JOIN {{ this }} tgt 
    ON src.hk_order_part = tgt.hk_order_part
WHERE tgt.hk_order_part IS NULL
{% endif %}
