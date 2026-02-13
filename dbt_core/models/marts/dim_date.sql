{{ config(materialized='table') }}

WITH RECURSIVE date_spine AS (
    SELECT CAST('1990-01-01' AS DATE) AS date_day
    UNION ALL
    SELECT DATEADD(day, 1, date_day)
    FROM date_spine
    WHERE date_day < '2000-01-01'
),

formatted AS (
    SELECT
        date_day AS date_key,
        YEAR(date_day) AS year,
        MONTH(date_day) AS month,
        MONTHNAME(date_day) AS month_name,
        DAY(date_day) AS day_of_month,
        DAYOFWEEK(date_day) AS day_of_week,
        QUARTER(date_day) AS quarter
    FROM date_spine
)

SELECT * FROM formatted