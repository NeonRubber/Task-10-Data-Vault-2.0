{{ config(materialized='table') }}

WITH 

orders_link AS (
    SELECT 
        hk_order,
        hk_customer
    FROM {{ ref('link_customer_order') }}
),

orders_details AS (
    SELECT 
        hk_order,
        o_orderstatus,
        o_totalprice,
        o_orderdate,
        o_orderpriority,
        load_dt
    FROM {{ ref('sat_order') }}
    -- Getting latest order state
    QUALIFY ROW_NUMBER() OVER (PARTITION BY hk_order ORDER BY load_dt DESC) = 1
)

SELECT
    ol.hk_order,
    ol.hk_customer,
    
    od.o_orderstatus AS order_status,
    od.o_totalprice AS total_amount,
    od.o_orderdate AS order_date,
    od.o_orderpriority AS priority,
    
    od.load_dt AS updated_at
    
FROM orders_link ol
INNER JOIN orders_details od
    ON ol.hk_order = od.hk_order