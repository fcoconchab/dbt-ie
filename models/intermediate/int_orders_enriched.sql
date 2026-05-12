-- Grain: one row per order_id
-- Business question: For each order, what is the full picture across items, shipping, and payments?
-- Purpose: Combine int_orders_with_items with shipping and payment metrics to create a single
--          order-level source of truth that marts can read from instead of repeating joins.
--
-- Without this model every mart that needed order plus shipping plus payment data would have
-- to do the same three joins from scratch. The definition of a completed order, a paid order,
-- or a late order would be copy-pasted across multiple files. If any of those definitions ever
-- needed to change you would have to find and update every mart individually. This model means
-- you define each thing once and every downstream model inherits it automatically.
--
-- All joins here are left joins from int_orders_with_items, so the row count always matches
-- the number of orders in stg_orders. No order gets dropped if it has no shipping or payment
-- record yet.
--
-- order_value_tier is added here so all marts share the same low, medium, high classification
-- without having to repeat the case when logic in each one.

with orders_with_items as (
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
        net_item_revenue
    from {{ ref('int_orders_with_items') }}
),

shipping as (
    select
        order_id,
        carrier,
        shipping_method,
        shipping_status,
        days_to_ship,
        days_late,
        is_late,
        is_delivered,
        shipping_performance_bucket
    from {{ ref('int_order_shipping_status') }}
),

payments as (
    select
        order_id,
        total_paid_amount,
        primary_payment_method,
        has_successful_payment,
        has_payment_issue,
        payment_status_summary
    from {{ ref('int_payments_by_order') }}
),

enriched as (
    select
        orders_with_items.order_id,
        orders_with_items.customer_id,
        orders_with_items.order_date,
        orders_with_items.status,
        orders_with_items.subtotal,
        orders_with_items.tax_amount,
        orders_with_items.shipping_cost,
        orders_with_items.discount_amount,
        orders_with_items.total_amount,
        orders_with_items.currency,
        orders_with_items.payment_method,
        orders_with_items.has_order_items,
        orders_with_items.order_item_count,
        orders_with_items.total_quantity,
        orders_with_items.gross_item_revenue,
        orders_with_items.net_item_revenue,
        shipping.carrier,
        shipping.shipping_method,
        shipping.shipping_status,
        shipping.days_to_ship,
        shipping.days_late,
        shipping.is_late,
        shipping.is_delivered,
        shipping.shipping_performance_bucket,
        payments.total_paid_amount,
        payments.primary_payment_method,
        payments.has_payment_issue,
        payments.payment_status_summary,
        case when orders_with_items.status = 'completed' then true else false end as is_completed_order,
        case when orders_with_items.status = 'cancelled' then true else false end as is_cancelled_order,
        case when orders_with_items.status = 'refunded'  then true else false end as is_refunded_order,
        payments.has_successful_payment                                           as is_paid,
        case
            when orders_with_items.total_amount < 50  then 'low'
            when orders_with_items.total_amount < 200 then 'medium'
            else 'high'
        end as order_value_tier
    from orders_with_items
    left join shipping using (order_id)
    left join payments using (order_id)
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
    net_item_revenue,
    carrier,
    shipping_method,
    shipping_status,
    days_to_ship,
    days_late,
    is_late,
    is_delivered,
    shipping_performance_bucket,
    total_paid_amount,
    primary_payment_method,
    has_payment_issue,
    payment_status_summary,
    is_completed_order,
    is_cancelled_order,
    is_refunded_order,
    is_paid,
    order_value_tier
from enriched