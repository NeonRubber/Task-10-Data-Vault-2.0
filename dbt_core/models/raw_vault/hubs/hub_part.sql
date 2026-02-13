{{ config(
    materialized='incremental',
    unique_key='hk_part',
    incremental_strategy='append'
) }}

WITH stg AS (
    SELECT DISTINCT
        hk_part,
        p_partkey,
        load_dt,
        record_source
    FROM {{ ref('stg_part') }}
)

SELECT
    src.hk_part,
    src.p_partkey,
    src.load_dt,
    src.record_source
FROM stg src
{% if is_incremental() %}
LEFT JOIN {{ this }} tgt 
    ON src.hk_part = tgt.hk_part
WHERE tgt.hk_part IS NULL
{% endif %}
