-- ---------------------------------------------------------------------------
-- Macro: hash_null_safe
-- Null-safe version of hash_sha256. Replaces NULL values with '^^' sentinel
-- before hashing to prevent ghost records from NULL key collisions.
-- Output: BINARY(32)
-- Usage: {{ hash_null_safe(['COL_A', 'COL_B']) }}
---------------------------------------------------------------------------

{% macro hash_null_safe(columns) %}
    CAST(SHA2_BINARY(
        CONCAT_WS('|',
            {%- for col in columns %}
            COALESCE(TRIM(UPPER(CAST({{ col }} AS VARCHAR))), '^^')
            {%- if not loop.last %}, {% endif %}
            {%- endfor %}
        ),
        256
    ) AS BINARY(32))
{% endmacro %}
