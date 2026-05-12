-- Grain: one row per order_id
-- Business question: For each order, how many items did we sell, and what is the gross vs net revenue?
-- Purpose: Summarize item-level data from stg_order_items into order-level metrics
--          (item count, total quantity, gross revenue, discounts, and net revenue)
--          to be reused by other order models like int_orders_with_items and int_orders_enriched.

with order_items as (
    select
        order_item_id,
        order_id,
        quantity,
        unit_price,
        discount_amount,
        total_price
    from {{ ref('stg_order_items') }}
),

summary as (
    select
        order_id,
        count(order_item_id)            as order_item_count,
        sum(quantity)                   as total_quantity,
        sum(unit_price * quantity)      as gross_item_revenue,
        sum(discount_amount)            as total_item_discount_amount,
        sum(total_price)                as net_item_revenue
    from order_items
    group by order_id
)

select
    order_id,
    order_item_count,
    total_quantity,
    gross_item_revenue,
    total_item_discount_amount,
    net_item_revenue
from summary