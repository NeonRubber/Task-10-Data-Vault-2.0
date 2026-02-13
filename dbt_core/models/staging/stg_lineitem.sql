{{
    config(
        materialized='incremental',
        unique_key=['l_orderkey', 'l_linenumber'],
        incremental_strategy='merge'
    )
}}

WITH source AS (

    SELECT
        *
    FROM {{ source('tpch', 'LINEITEM') }}

    {% if is_incremental() %}
    WHERE l_shipdate > (SELECT MAX(l_shipdate) FROM {{ this }})
    {% endif %}

),

staged AS (

    SELECT
        -- Hub key
        {{ hash_sha256(['L_ORDERKEY', 'L_LINENUMBER']) }} AS hk_lineitem,

        -- Link key: LineItem <-> Order
        {{ hash_sha256(['L_ORDERKEY', 'L_LINENUMBER', 'L_ORDERKEY']) }} AS hk_lineitem_order,

        -- Link key: Part <-> Supplier
        {{ hash_sha256(['L_PARTKEY', 'L_SUPPKEY']) }} AS hk_lineitem_part_supplier,

        -- Hub key references
        {{ hash_sha256(['L_ORDERKEY']) }} AS hk_order,
        {{ hash_sha256(['L_PARTKEY']) }}  AS hk_part,
        {{ hash_sha256(['L_SUPPKEY']) }}  AS hk_supplier,

        -- Business keys
        l_orderkey,
        l_linenumber,
        l_partkey,
        l_suppkey,

        -- Descriptive attributes
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
        l_comment,

        -- Metadata
        CURRENT_TIMESTAMP() AS load_dt,
        'SNOWFLAKE_TPCH'   AS record_source

    FROM source

)

SELECT * FROM staged
