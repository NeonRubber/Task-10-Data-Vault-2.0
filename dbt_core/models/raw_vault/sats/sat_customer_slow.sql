{{ config(
    materialized='incremental',
    unique_key=['hk_customer', 'load_dt'],
    incremental_strategy='append'
) }}

WITH stg AS (
    SELECT
        hk_customer,
        c_name,
        c_address,
        c_mktsegment,
        c_comment,
        -- Using hash_sha256
        {{ hash_sha256(['c_name', 'c_address', 'c_mktsegment', 'c_comment']) }} AS hash_diff,
        load_dt,
        record_source
    FROM {{ ref('stg_customer') }}
),

latest_records AS (
    {% if is_incremental() %}
        SELECT hk_customer, hash_diff FROM {{ this }}
        QUALIFY ROW_NUMBER() OVER (PARTITION BY hk_customer ORDER BY load_dt DESC) = 1
    {% else %}
        SELECT NULL::BINARY(32) AS hk_customer, NULL::BINARY(32) AS hash_diff WHERE 1=0
    {% endif %}
)

SELECT
    src.hk_customer,
    src.hash_diff,
    src.c_name,
    src.c_address,
    src.c_mktsegment,
    src.c_comment,
    src.load_dt,
    src.record_source
FROM stg src
LEFT JOIN latest_records tgt 
    ON src.hk_customer = tgt.hk_customer
WHERE tgt.hk_customer IS NULL OR src.hash_diff != tgt.hash_diff
