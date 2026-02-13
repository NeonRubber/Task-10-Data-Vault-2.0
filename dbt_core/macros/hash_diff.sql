-- -----------------------------------------------------------------------------
-- Macro: hash_diff
-- Hashes a set of descriptive attributes for satellite change detection.
-- Uses the same normalization as hash_sha256 but semantically represents
-- a change hash diff rather than a business key hash.

   Output: BINARY(32)
   Usage: {{ hash_diff(['COL_A', 'COL_B', 'COL_C']) }}
---------------------------------------------------------------------------

{% macro hash_diff(columns) %}
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
