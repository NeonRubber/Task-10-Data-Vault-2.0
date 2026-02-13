{{ config(
    materialized='incremental',
    unique_key=['customer_sk', 'valid_from'], 
    incremental_strategy='merge',
    tags=['marts']
) }}

WITH fast_sat AS (
    SELECT 
        hk_customer,
        c_phone,
        c_acctbal,
        load_dt
    FROM {{ ref('sat_customer_fast') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY hk_customer ORDER BY load_dt DESC) = 1
),

slow_sat AS (
    SELECT 
        hk_customer,
        c_mktsegment,
        c_name,
        c_address,
        load_dt
    FROM {{ ref('sat_customer_slow') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY hk_customer ORDER BY load_dt DESC) = 1
),

joined_data AS (
    SELECT
        h.hk_customer AS customer_sk,
        h.c_custkey,
        
        f.c_phone,
        f.c_acctbal,
        
        s.c_name,
        s.c_address,
        s.c_mktsegment,

        GREATEST(
            COALESCE(f.load_dt, '1900-01-01'::timestamp), 
            COALESCE(s.load_dt, '1900-01-01'::timestamp)
        ) AS valid_from,

        '9999-12-31'::timestamp AS valid_to,

        TRUE AS is_current
        
    FROM {{ ref('hub_customer') }} h
    LEFT JOIN fast_sat f ON h.hk_customer = f.hk_customer
    LEFT JOIN slow_sat s ON h.hk_customer = s.hk_customer
),

final_with_hash AS (
    SELECT 
        *,
        {{ hash_sha256(['c_phone', 'c_acctbal', 'c_mktsegment', 'c_name', 'c_address']) }} AS hash_diff_dim
    FROM joined_data
)

SELECT * FROM final_with_hash

{% if is_incremental() %}
    -- Filter out records that are already present (exact match on hash_diff AND valid_from)
    -- Or just rely on unique_key merge which will insert if (customer_sk, valid_from) is new.
    -- To accumulate history, we want to INSERT if hash_diff changed, which implies new valid_from (load_dt).
    WHERE 1=1 -- Let the MERGE handle it via unique_key
    -- Although typically we filter to optimize.
    -- If we filter by hash_diff NOT IN, we get the new row.
    AND hash_diff_dim NOT IN (SELECT hash_diff_dim FROM {{ this }})
{% endif %}