{{ config(
    materialized='incremental',
    unique_key=['hk_lineitem', 'load_dt'],
    incremental_strategy='append'
) }}

WITH stg AS (
    SELECT
        hk_lineitem,
        l_quantity,
        l_extendedprice,
        l_discount,
        l_tax,
        l_returnflag,
        l_linestatus,
        l_shipdate,
        l_commitdate,
        l_receiptdate,
        l_shipinstruct,
        l_shipmode,
        {{ hash_diff([
            'l_quantity', 'l_extendedprice', 'l_discount', 'l_tax',
            'l_returnflag', 'l_linestatus', 'l_shipdate', 'l_commitdate',
            'l_receiptdate', 'l_shipinstruct', 'l_shipmode'
        ]) }} AS hash_diff,
        load_dt,
        record_source
    FROM {{ ref('stg_lineitem') }}
),

latest_records AS (
    {% if is_incremental() %}
        SELECT hk_lineitem, hash_diff FROM {{ this }}
        QUALIFY ROW_NUMBER() OVER (PARTITION BY hk_lineitem ORDER BY load_dt DESC) = 1
    {% else %}
        SELECT NULL::BINARY(32) AS hk_lineitem, NULL::BINARY(32) AS hash_diff WHERE 1=0
    {% endif %}
)

SELECT
    src.hk_lineitem,
    src.hash_diff,
    src.l_quantity,
    src.l_extendedprice,
    src.l_discount,
    src.l_tax,
    src.l_returnflag,
    src.l_linestatus,
    src.l_shipdate,
    src.l_commitdate,
    src.l_receiptdate,
    src.l_shipinstruct,
    src.l_shipmode,
    src.load_dt,
    src.record_source
FROM stg src
LEFT JOIN latest_records tgt 
    ON src.hk_lineitem = tgt.hk_lineitem
WHERE tgt.hk_lineitem IS NULL OR src.hash_diff != tgt.hash_diff