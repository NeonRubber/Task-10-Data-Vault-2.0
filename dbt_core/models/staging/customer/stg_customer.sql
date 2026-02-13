{{
    config(
        materialized='view'
    )
}}

WITH source AS (

    SELECT
        *
    FROM {{ source('tpch', 'customer') }}

),

staged AS (

    SELECT
        -- Hub key
        {{ hash_sha256(['C_CUSTKEY']) }} AS hk_customer,

        -- Link key: Customer <-> Nation
        {{ hash_sha256(['C_CUSTKEY', 'C_NATIONKEY']) }} AS hk_customer_nation,

        -- Business keys
        c_custkey,
        c_nationkey,

        -- Descriptive attributes
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_mktsegment,
        c_comment,

        -- Metadata
        {{ dbt.string_literal(run_started_at.strftime('%Y-%m-%d %H:%M:%S')) }}::timestamp_ntz AS load_dt,
        'SNOWFLAKE_TPCH' AS record_source

    FROM source

)

SELECT * FROM staged
