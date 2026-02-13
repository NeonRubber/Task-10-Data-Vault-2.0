{{ config(
    materialized='incremental',
    unique_key='hk_order_part',
    incremental_strategy='append'
) }}

{# 
   Standard Data Vault 2.0 Link:
   Only contains the hash key of the link, hash keys of the hubs, and metadata.
   Business keys (like orderkey or linenumber) are strictly excluded.
#}

SELECT DISTINCT
    t1.hk_order_part,
    t1.hk_order,
    t1.hk_part,
    t1.load_dt,
    t1.record_source

FROM {{ ref('stg_lineitem') }} t1

{% if is_incremental() %}
    LEFT JOIN {{ this }} t2 
    ON t1.hk_order_part = t2.hk_order_part
    WHERE t2.hk_order_part IS NULL
{% endif %}