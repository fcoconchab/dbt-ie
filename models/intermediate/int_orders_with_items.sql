-- Grain: one row per order_id
-- Business question: For each order, what are its core details and what item-level revenue
--                    metrics does it have?
-- Purpose: Combine order header data from stg_orders with the aggregated item metrics from
--          int_order_items_summary to form a single order record that knows whether it has
--          items, how many, and the associated revenue.
--
-- stg_orders drives the join. Every order shows up in the output even if it has no items yet,
-- which is safer than an inner join that would silently drop those orders. has_order_items
-- flags orders with no matching item records so downstream models can handle them explicitly
-- rather than relying on null checks across multiple columns.
--
-- subtotal is the order value before tax and shipping. total_amount is what the customer
-- actually paid once everything is added. net_item_revenue is what you get by adding up the
-- individual line items from stg_order_items. They come from different places and will not
-- always match exactly. revenue_variance makes that gap visible and queryable so data quality
-- issues do not go unnoticed.

with orders as (
    select
        order_id,
        customer_id,
        order_date,
        status,
        subtotal,
        tax_amount,
        shipping_cost,
        discount_amount,
        total_amount,
        currency,
        payment_method
    from {{ ref('stg_orders') }}
),

order_items_summary as (
    select
        order_id,
        order_item_count,
        total_quantity,
        gross_item_revenue,
        total_item_discount_amount,
        net_item_revenue
    from {{ ref('int_order_items_summary') }}
),

merged as (
    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        orders.status,
        orders.subtotal,
        orders.tax_amount,
        orders.shipping_cost,
        orders.discount_amount,
        orders.total_amount,
        orders.currency,
        orders.payment_method,
        case
            when order_items_summary.order_id is not null then true
            else false
        end                                         as has_order_items,
        order_items_summary.order_item_count,
        order_items_summary.total_quantity,
        order_items_summary.gross_item_revenue,
        order_items_summary.total_item_discount_amount,
        order_items_summary.net_item_revenue,
        orders.subtotal - coalesce(order_items_summary.net_item_revenue, 0) as revenue_variance
    from orders
    left join order_items_summary using (order_id)
)

select
    order_id,
    customer_id,
    order_date,
    status,
    subtotal,
    tax_amount,
    shipping_cost,
    discount_amount,
    total_amount,
    currency,
    payment_method,
    has_order_items,
    order_item_count,
    total_quantity,
    gross_item_revenue,
    total_item_discount_amount,
    net_item_revenue,
    revenue_variance
from merged