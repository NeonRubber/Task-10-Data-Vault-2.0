{{
    config(
        materialized='incremental',
        unique_key=['hk_customer', 'hash_diff'],
        incremental_strategy='append'
    )
}}

{# ---------------------------------------------------------------------------
   Business Satellite — Customer Marketing
   Enriches HUB_CUSTOMER with external marketing data from the
   customer_marketing seed (segment, vip_flag, manager_id).
--------------------------------------------------------------------------- #}

WITH hub AS (

    SELECT
        hk_customer,
        c_custkey
    FROM {{ ref('hub_customer') }}

),

marketing AS (

    SELECT
        customer_id,
        segment,
        vip_flag,
        manager_id
    FROM {{ ref('customer_marketing') }}

),

joined AS (

    SELECT
        h.hk_customer,
        m.segment,
        m.vip_flag,
        m.manager_id,
        {{ hash_diff(['m.segment', 'm.vip_flag', 'm.manager_id']) }} AS hash_diff,
        CURRENT_TIMESTAMP() AS load_dt,
        'SEED_MARKETING' AS record_source
    FROM hub h
    INNER JOIN marketing m
        ON h.c_custkey = m.customer_id

)

SELECT
    hk_customer,
    hash_diff,
    segment,
    vip_flag,
    manager_id,
    load_dt,
    record_source
FROM joined

{% if is_incremental() %}
WHERE CONCAT(hk_customer, hash_diff) NOT IN (
    SELECT CONCAT(hk_customer, hash_diff) FROM {{ this }}
)
{% endif %}
