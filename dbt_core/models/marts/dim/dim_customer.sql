{{
    config(
        materialized='incremental',
        unique_key=['customer_sk', 'valid_from'],
        incremental_strategy='merge'
    )
}}



WITH pit AS (
    SELECT * FROM {{ ref('pit_customer') }}
    {% if is_incremental() %}
    WHERE pit_load_dt > (SELECT MAX(valid_from) FROM {{ this }})
    {% endif %}
),

hub AS (
    SELECT hk_customer, c_custkey, record_source
    FROM {{ ref('hub_customer') }}
),

sat_fast AS (
    SELECT * FROM {{ ref('sat_customer_fast') }}
),

sat_slow AS (
    SELECT * FROM {{ ref('sat_customer_slow') }}
),

joined_data AS (
    SELECT
        p.hk_customer AS customer_sk,
        h.c_custkey,
        f.c_phone,
        f.c_acctbal,

        s.c_name,
        s.c_address,
        s.c_mktsegment,
        p.pit_load_dt AS valid_from,
        h.record_source

    FROM pit p
    INNER JOIN hub h 
        ON p.hk_customer = h.hk_customer

    LEFT JOIN sat_fast f 
        ON p.hk_customer = f.hk_customer 
        AND p.sat_customer_fast_load_dt = f.load_dt

    LEFT JOIN sat_slow s 
        ON p.hk_customer = s.hk_customer 
        AND p.sat_customer_slow_load_dt = s.load_dt
),

calc_window AS (
    SELECT 
        *,
        LEAD(valid_from) OVER (PARTITION BY customer_sk ORDER BY valid_from) AS next_valid_from
    FROM joined_data
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
    record_source,
    COALESCE(next_valid_from, TO_TIMESTAMP('9999-12-31')) AS valid_to,
    CASE 
        WHEN next_valid_from IS NULL THEN TRUE 
        ELSE FALSE 
    END AS is_current
FROM calc_window