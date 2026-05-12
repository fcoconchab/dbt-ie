-- Grain: one row per order_id
-- Business question: For each order, when was it shipped and delivered, and was it on time?
-- Purpose: Enrich each order with shipping timing and performance metrics so downstream models
--          can analyse delivery speed and delays without re-joining the raw shipping table.
--
-- I am defining late based on delivery date, not ship date. The customer does not care when
-- the package left the warehouse, they care when it arrived at their door. An order that
-- shipped late but arrived on time should not count as late.
--
-- An order is only marked late once it has actually been delivered and the delivery date was
-- after the estimated date. If it has not arrived yet we cannot call it late, we just do not
-- know yet. is_delivered makes that distinction explicit so performance metrics are only
-- calculated on orders that have completed the delivery journey.
--
-- days_late can be negative for early deliveries, which is intentional. A negative value
-- means the carrier delivered ahead of schedule.

with orders as (
    select
        order_id,
        order_date
    from {{ ref('stg_orders') }}
),

shipping as (
    select
        order_id,
        carrier,
        shipping_method,
        shipping_status,
        ship_date,
        estimated_delivery,
        actual_delivery
    from {{ ref('stg_shipping') }}
),

merged as (
    select
        orders.order_id,
        orders.order_date,
        shipping.carrier,
        shipping.shipping_method,
        shipping.shipping_status,
        shipping.ship_date,
        shipping.estimated_delivery,
        shipping.actual_delivery,
        datediff('day', cast(orders.order_date as date), cast(shipping.ship_date as date))                as days_to_ship,
        datediff('day', cast(shipping.estimated_delivery as date), cast(shipping.actual_delivery as date)) as days_late,
        case
            when shipping.actual_delivery > shipping.estimated_delivery then true
            else false
        end as is_late,
        case
            when shipping.actual_delivery is not null then true
            else false
        end as is_delivered,
        case
            when shipping.ship_date is null then 'not_shipped'
            when shipping.actual_delivery < shipping.estimated_delivery then 'early'
            when shipping.actual_delivery = shipping.estimated_delivery then 'on_time'
            when shipping.actual_delivery > shipping.estimated_delivery then 'late'
            else 'unknown'
        end as shipping_performance_bucket
    from orders
    left join shipping using (order_id)
)

select
    order_id,
    order_date,
    carrier,
    shipping_method,
    shipping_status,
    ship_date,
    estimated_delivery,
    actual_delivery,
    days_to_ship,
    days_late,
    is_late,
    is_delivered,
    shipping_performance_bucket
from merged