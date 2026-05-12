-- ===========================================================================
-- 1. THE FAN-OUT CHECK (Row Counts)
-- ===========================================================================
-- Goal: The two numbers should be exactly identical.
-- If int_orders_enriched has more rows, a JOIN is duplicating data.
select 
    'stg_orders' as table_name, count(*) as total_rows 
from {{ ref('stg_orders') }}
union all
select 
    'int_orders_enriched' as table_name, count(*) as total_rows 
from {{ ref('int_orders_enriched') }};


-- ===========================================================================
-- 2. THE EDGE-CASE SPOT CHECK
-- ===========================================================================
-- Goal: Verify business flags are triggering correctly.
-- Check: Are is_late orders also is_delivered? 
-- Check: Does has_payment_issue capture checkout friction?
select 
    order_id,
    status,
    total_amount,
    order_value_tier,
    payment_status_summary,
    has_payment_issue,
    shipping_performance_bucket,
    is_delivered,
    is_late
from {{ ref('int_orders_enriched') }}
where has_payment_issue = true 
   or is_late = true
limit 15;


-- ===========================================================================
-- 3. THE REVENUE VARIANCE INVESTIGATION
-- ===========================================================================
-- Goal: We have 2,125 failures. Let's see if it's a "Discount Bug."
-- Hypothesis: The subtotal in the header doesn't match the items because 
--             discounts were only applied to the header, not the line items.
select 
    order_id,
    subtotal,
    net_item_revenue,
    discount_amount,
    -- Calculate the gap
    (subtotal - net_item_revenue) as raw_variance,
    -- Check if the gap IS the discount
    case 
        when abs((subtotal - net_item_revenue) - discount_amount) < 0.05 then 'Discount Discrepancy'
        else 'Other Issue'
    end as variance_type
from {{ ref('int_orders_with_items') }}
where abs(subtotal - net_item_revenue) > 0.05
order by abs(subtotal - net_item_revenue) desc
limit 20;