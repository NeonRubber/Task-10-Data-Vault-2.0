{{
    config(
        materialized='incremental',
        unique_key=['customer_sk', 'valid_from'],
        incremental_strategy='merge'
    )
}}

-- SCD Type 2 Dimension: Customer
-- Join Hub + Satellites (Fast & Slow) -> Dimensions
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

source_data AS (
    -- 1. Combine new data from Vault (Hub + Sat)
    SELECT
        h.hk_customer AS customer_sk,
        h.c_custkey,
        s.c_name,
        s.c_address,
        f.c_phone,
        f.c_acctbal,
        s.c_mktsegment,
        -- c_comment is not in sat_customer_slow definition in this project, omitting
        GREATEST(
            COALESCE(f.load_dt, '1900-01-01'::timestamp), 
            COALESCE(s.load_dt, '1900-01-01'::timestamp)
        ) AS valid_from,
        h.record_source
    FROM {{ ref('hub_customer') }} h
    LEFT JOIN fast_sat f ON h.hk_customer = f.hk_customer
    LEFT JOIN slow_sat s ON h.hk_customer = s.hk_customer
    
    {% if is_incremental() %}
    -- Take only fresh data
    WHERE GREATEST(
            COALESCE(f.load_dt, '1900-01-01'::timestamp), 
            COALESCE(s.load_dt, '1900-01-01'::timestamp)
        ) > (SELECT MAX(valid_from) FROM {{ this }})
    {% endif %}
),

active_history AS (
    -- 2. Pull active records to close them
    {% if is_incremental() %}
    SELECT
        customer_sk,
        c_custkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_mktsegment,
        valid_from,
        record_source
    FROM {{ this }}
    WHERE is_current = TRUE
    {% else %}
    SELECT 
        NULL::BINARY(32) as customer_sk, 
        NULL::NUMBER as c_custkey,
        NULL::VARCHAR as c_name,
        NULL::VARCHAR as c_address,
        NULL::VARCHAR as c_phone,
        NULL::NUMBER as c_acctbal,
        NULL::VARCHAR as c_mktsegment,
        NULL::TIMESTAMP as valid_from,
        NULL::VARCHAR as record_source
    WHERE 1=0
    {% endif %}
),

combined_data AS (
    -- 3. Union
    SELECT * FROM source_data
    UNION
    SELECT * FROM active_history
),

final_calc AS (
    -- 4. Re-calculate SCD2 windows
    SELECT
        customer_sk,
        c_custkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_mktsegment,
        valid_from,
        record_source,
        -- LEAD calculates start date of NEXT record, which becomes end date of CURRENT
        LEAD(valid_from) OVER (PARTITION BY customer_sk ORDER BY valid_from) AS next_valid_from
    FROM combined_data
)

SELECT
    customer_sk,
    c_custkey,
    c_name,
    c_address,
    c_phone,
    c_acctbal,
    c_mktsegment,
    valid_from,
    -- If no next record, this is current until forever
    COALESCE(next_valid_from, TO_TIMESTAMP('9999-12-31')) AS valid_to,
    -- Flag current record
    CASE 
        WHEN next_valid_from IS NULL THEN TRUE 
        ELSE FALSE 
    END AS is_current
FROM final_calc