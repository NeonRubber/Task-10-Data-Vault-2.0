{{
    config(
        materialized='incremental',
        unique_key=['hk_order_customer', 'load_dt'],
        incremental_strategy='append'
    )
}}

{# ---------------------------------------------------------------------------
   Effectivity Satellite on LINK_CUSTOMER_ORDER
   Fixed: QUALIFY syntax placement corrected.
--------------------------------------------------------------------------- #}

WITH link AS (
    SELECT
        hk_order_customer,
        hk_order,
        hk_customer,
        record_source
    FROM {{ ref('link_customer_order') }}
),

-- Getting latest order status
latest_order_status AS (
    SELECT
        hk_order,
        o_orderstatus
    FROM {{ ref('sat_order') }}
),

-- Computing business logic (Status)
logic_layer AS (
    SELECT
        l.hk_order_customer,
        l.hk_order,
        l.hk_customer,
        CASE
            WHEN lo.o_orderstatus = 'F' THEN FALSE
            ELSE TRUE
        END AS is_active,
        CASE
            WHEN lo.o_orderstatus = 'F' THEN 'CLOSED'
            WHEN lo.o_orderstatus = 'O' THEN 'ACTIVE'
            WHEN lo.o_orderstatus = 'P' THEN 'ACTIVE'
            ELSE 'UNKNOWN'
        END AS relationship_status,
        l.record_source
    FROM link l
    INNER JOIN latest_order_status lo
        ON l.hk_order = lo.hk_order
),

-- Adding Hash Diff
hashed_source AS (
    SELECT
        hk_order_customer,
        hk_order,
        hk_customer,
        is_active,
        relationship_status,
        record_source,
        CURRENT_TIMESTAMP() AS load_dt,
        -- Hashing status to track changes
        {{ hash_sha256(['is_active', 'relationship_status']) }} AS hash_diff
    FROM logic_layer
),

-- Getting latest target record (incremental)
latest_target AS (
    {% if is_incremental() %}
        SELECT hk_order_customer, hash_diff 
        FROM {{ this }}
        QUALIFY ROW_NUMBER() OVER (PARTITION BY hk_order_customer ORDER BY load_dt DESC) = 1
    {% else %}
        SELECT NULL::BINARY(32) AS hk_order_customer, NULL::BINARY(32) AS hash_diff WHERE 1=0
    {% endif %}
)

SELECT
    src.hk_order_customer,
    src.hk_order,
    src.hk_customer,
    src.is_active,
    src.relationship_status,
    src.load_dt,
    src.record_source,
    src.hash_diff
FROM hashed_source src
LEFT JOIN latest_target tgt
    ON src.hk_order_customer = tgt.hk_order_customer
WHERE 
    -- Inserting if new or changed
    tgt.hk_order_customer IS NULL 
    OR src.hash_diff != tgt.hash_diff