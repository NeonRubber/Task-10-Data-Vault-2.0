{{ config(
    materialized='incremental',
    unique_key=['hk_order', 'load_dt'],
    incremental_strategy='append'
) }}

WITH stg AS (
    SELECT
        hk_order,
        o_orderstatus,
        o_totalprice,
        o_orderdate,
        o_orderpriority,
        o_clerk,
        o_shippriority,
        o_comment,
        {{ hash_diff([
            'o_orderstatus', 'o_totalprice', 'o_orderdate',
            'o_orderpriority', 'o_clerk', 'o_shippriority', 'o_comment'
        ]) }} AS hash_diff,
        load_dt,
        record_source
    FROM {{ ref('stg_orders') }}
),

latest_records AS (
    {% if is_incremental() %}
        SELECT hk_order, hash_diff FROM {{ this }}
        QUALIFY ROW_NUMBER() OVER (PARTITION BY hk_order ORDER BY load_dt DESC) = 1
    {% else %}
        SELECT NULL::BINARY(32) AS hk_order, NULL::BINARY(32) AS hash_diff WHERE 1=0
    {% endif %}
)

SELECT
    src.hk_order,
    src.hash_diff,
    src.o_orderstatus,
    src.o_totalprice,
    src.o_orderdate,
    src.o_orderpriority,
    src.o_clerk,
    src.o_shippriority,
    src.o_comment,
    src.load_dt,
    src.record_source
FROM stg src
LEFT JOIN latest_records tgt 
    ON src.hk_order = tgt.hk_order
WHERE tgt.hk_order IS NULL OR src.hash_diff != tgt.hash_diff