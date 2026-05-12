-- This test checks if the order subtotal matches the sum of the items.
-- In dbt, a singular test PASSES if it returns 0 rows. 
-- If it returns ANY rows, the test FAILS and warns us of a data issue.

select 
    order_id,
    subtotal,
    net_item_revenue,
    abs(subtotal - net_item_revenue) as variance
from {{ ref('int_orders_with_items') }}
where abs(subtotal - net_item_revenue) > 0.05 -- Allowing a tiny 5-cent margin for rounding