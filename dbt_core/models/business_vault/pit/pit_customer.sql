{{
    config(
        materialized='incremental',
        unique_key='pit_key',
        incremental_strategy='merge'
    )
}}

{# ---------------------------------------------------------------------------
   Sparse PIT for HUB_CUSTOMER
   Records a new row only when either SAT_CUSTOMER_FAST or SAT_CUSTOMER_SLOW
   has a change (new load_dt). This avoids dense daily snapshots.
--------------------------------------------------------------------------- #}

WITH sat_fast AS (

    SELECT
        hk_customer,
        load_dt AS sat_fast_load_dt,
        hash_diff AS sat_fast_hash_diff
    FROM {{ ref('sat_customer_fast') }}

),

sat_slow AS (

    SELECT
        hk_customer,
        load_dt AS sat_slow_load_dt,
        hash_diff AS sat_slow_hash_diff
    FROM {{ ref('sat_customer_slow') }}

),

-- Collect all distinct change timestamps per customer
change_events AS (

    SELECT hk_customer, sat_fast_load_dt AS event_dt
    FROM sat_fast
    UNION
    SELECT hk_customer, sat_slow_load_dt AS event_dt
    FROM sat_slow

),

-- For each change event, find the latest satellite record at or before that point
pit AS (

    SELECT
        ce.hk_customer,
        ce.event_dt AS pit_load_dt,

        -- Latest fast satellite version at this point in time
        (
            SELECT MAX(sf.sat_fast_load_dt)
            FROM sat_fast sf
            WHERE sf.hk_customer = ce.hk_customer
              AND sf.sat_fast_load_dt <= ce.event_dt
        ) AS sat_customer_fast_load_dt,

        -- Latest slow satellite version at this point in time
        (
            SELECT MAX(ss.sat_slow_load_dt)
            FROM sat_slow ss
            WHERE ss.hk_customer = ce.hk_customer
              AND ss.sat_slow_load_dt <= ce.event_dt
        ) AS sat_customer_slow_load_dt

    FROM change_events ce

),

final AS (

    SELECT
        {{ hash_sha256(['hk_customer', 'pit_load_dt']) }} AS pit_key,
        hk_customer,
        pit_load_dt,
        sat_customer_fast_load_dt,
        sat_customer_slow_load_dt
    FROM pit
    WHERE sat_customer_fast_load_dt IS NOT NULL
       OR sat_customer_slow_load_dt IS NOT NULL

)

SELECT * FROM final

{% if is_incremental() %}
WHERE pit_key NOT IN (SELECT pit_key FROM {{ this }})
{% endif %}
