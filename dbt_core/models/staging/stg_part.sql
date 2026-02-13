{{
    config(
        materialized='view'
    )
}}

WITH source AS (

    SELECT
        *
    FROM {{ source('tpch', 'PART') }}

),

staged AS (

    SELECT
        -- Hub key
        {{ hash_sha256(['P_PARTKEY']) }} AS hk_part,

        -- Business keys
        p_partkey,

        -- Descriptive attributes
        p_name,
        p_mfgr,
        p_brand,
        p_type,
        p_size,
        p_container,
        p_retailprice,
        p_comment,

        -- Metadata
        CURRENT_TIMESTAMP() AS load_dt,
        'SNOWFLAKE_TPCH'   AS record_source

    FROM source

)

SELECT * FROM staged
