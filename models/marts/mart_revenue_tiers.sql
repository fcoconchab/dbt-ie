-- This model classifies completed orders into revenue tiers
-- It calls the classify_revenue macro twice with different thresholds

select
    order_id,
    customer_id,
    order_date,
    status,
    total_amount,

    -- Default thresholds: low < 100, high >= 500
    {{ classify_revenue('total_amount') }}              as revenue_tier,

    -- Strict thresholds: low < 50, high >= 200
    {{ classify_revenue('total_amount',
        low_threshold=50,
        high_threshold=200) }}                          as revenue_tier_strict

from {{ ref('int_orders_enriched') }}
where status = 'completed'   -- only completed orders per assignment