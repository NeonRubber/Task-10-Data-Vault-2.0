{{ config(
    materialized='table',
    tags=['business_vault', 'bridge']
) }}

/*
    BRIDGE TABLE: Customer <-> Orders
    Collects keys from Hubs and Link into one table to accelerate queries.
*/

WITH link_data AS (
    SELECT * FROM {{ ref('link_customer_order') }}
),

hub_customer AS (
    SELECT * FROM {{ ref('hub_customer') }}
),

hub_order AS (
    SELECT * FROM {{ ref('hub_order') }}
)

SELECT
    -- 1. Primary Link Key
    l.hk_order_customer,
    
    -- 2. Metadata (from link)
    l.load_dt,
    l.record_source,
    
    -- 3. CUSTOMER Data (from Hub Customer)
    hc.hk_customer,
    hc.c_custkey,

    -- 4. ORDER Data (from Hub Order)
    ho.hk_order,
    ho.o_orderkey

FROM link_data l

-- Join Customer Hub by hash key
INNER JOIN hub_customer hc 
    ON l.hk_customer = hc.hk_customer

-- Join Order Hub by hash key
INNER JOIN hub_order ho 
    ON l.hk_order = ho.hk_order