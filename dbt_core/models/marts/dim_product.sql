{{ config(materialized='view') }}

WITH hub AS (
    SELECT 
        hk_part, 
        p_partkey 
    FROM {{ ref('hub_part') }}
),

sat AS (
    SELECT 
        hk_part,
        p_name,
        p_mfgr,
        p_brand,
        p_type,
        p_size,
        p_container,
        p_retailprice,
        p_comment,
        load_dt,
        record_source
    FROM {{ ref('sat_part') }}
)

SELECT
    -- Keys
    h.hk_part AS product_sk,  
    h.p_partkey,              

    -- Attributes
    s.p_name AS name,
    s.p_mfgr AS manufacturer,
    s.p_brand AS brand,
    s.p_type AS type,
    s.p_size AS size,
    s.p_container AS container,
    s.p_retailprice AS retail_price,
    s.p_comment AS comment,

    -- Мetadata
    s.load_dt,
    s.record_source

FROM hub h
INNER JOIN sat s 
    ON h.hk_part = s.hk_part