{{ config(
    materialized='incremental',
    unique_key=['hk_part', 'load_dt'],
    incremental_strategy='append'
) }}

WITH stg AS (
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
        -- Hash Diff
        {{ hash_sha256([
            'p_name', 'p_mfgr', 'p_brand', 'p_type', 
            'p_size', 'p_container', 'p_retailprice', 'p_comment'
        ]) }} AS hash_diff,
        load_dt,
        record_source
    FROM {{ ref('stg_part') }}
),

latest_records AS (
    {% if is_incremental() %}
        SELECT hk_part, hash_diff FROM {{ this }}
        QUALIFY ROW_NUMBER() OVER (PARTITION BY hk_part ORDER BY load_dt DESC) = 1
    {% else %}
        SELECT NULL::BINARY(32) AS hk_part, NULL::BINARY(32) AS hash_diff WHERE 1=0
    {% endif %}
)

SELECT
    src.hk_part,
    src.hash_diff,
    src.p_name,
    src.p_mfgr,
    src.p_brand,
    src.p_type,
    src.p_size,
    src.p_container,
    src.p_retailprice,
    src.p_comment,
    src.load_dt,
    src.record_source
FROM stg src
LEFT JOIN latest_records tgt 
    ON src.hk_part = tgt.hk_part
WHERE tgt.hk_part IS NULL OR src.hash_diff != tgt.hash_diff
