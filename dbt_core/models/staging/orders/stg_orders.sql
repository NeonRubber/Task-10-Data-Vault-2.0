{{
    config(
        materialized='incremental',
        unique_key='o_orderkey',
        incremental_strategy='merge'
    )
}}

WITH source AS (

    SELECT
        *
    FROM {{ source('tpch', 'orders') }}

    {% if is_incremental() %}
    WHERE o_orderdate > (SELECT MAX(o_orderdate) FROM {{ this }})
    {% endif %}

),

staged AS (

    SELECT
        -- Hub keys
        {{ hash_sha256(['O_ORDERKEY']) }}  AS hk_order,
        {{ hash_sha256(['O_CUSTKEY']) }}   AS hk_customer,

        -- Link key: Order <-> Customer
        {{ hash_sha256(['O_ORDERKEY', 'O_CUSTKEY']) }} AS hk_order_customer,

        -- Business keys
        o_orderkey,
        o_custkey,

        -- Descriptive attributes
        o_orderstatus,
        o_totalprice,
        o_orderdate,
        o_orderpriority,
        o_clerk,
        o_shippriority,
        o_comment,

        -- Metadata
        {{ dbt.string_literal(run_started_at.strftime('%Y-%m-%d %H:%M:%S')) }}::timestamp_ntz AS load_dt,
        'SNOWFLAKE_TPCH'   AS record_source

    FROM source

)

SELECT * FROM staged
