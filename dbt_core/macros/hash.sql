-- ---------------------------------------------------------------------------
-- Macro: hash_sha256
-- Accepts a list of column names, applies TRIM(UPPER(...)) to each,
-- concatenates them with '|' separator, and returns SHA2(..., 256).
-- Output: BINARY(32) for storage optimization
-- Usage: {{ hash_sha256(['COL_A', 'COL_B']) }}
---------------------------------------------------------------------------

{% macro hash_sha256(columns) %}
    CAST(SHA2_BINARY(
        CONCAT_WS('|',
            {%- for col in columns %}
            TRIM(UPPER(CAST({{ col }} AS VARCHAR)))
            {%- if not loop.last %}, {% endif %}
            {%- endfor %}
        ),
        256
    ) AS BINARY(32))
{% endmacro %}