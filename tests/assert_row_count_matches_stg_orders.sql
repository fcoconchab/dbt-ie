-- This test guarantees that our enriched model has exactly the same number of rows as the staging model.
-- If it returns a row, it means a bad JOIN caused a fan-out (duplicate rows).

with staging_count as (
    select count(*) as row_count from {{ ref('stg_orders') }}
),

enriched_count as (
    select count(*) as row_count from {{ ref('int_orders_enriched') }}
)

select 
    staging_count.row_count as stg_rows,
    enriched_count.row_count as enriched_rows
from staging_count
cross join enriched_count
where staging_count.row_count != enriched_count.row_count