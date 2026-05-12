-- Grain: one row per order_id
-- Business question: For each order, how many items did we sell and what is the gross vs net revenue?
-- Purpose: Collapse stg_order_items from item-grain to order-grain so it can be safely joined
--          to stg_orders without duplicating rows.
--
-- stg_order_items has multiple rows per order, one per line item. If you join it directly to
-- stg_orders you get one row per item instead of one per order. An order with 5 items would
-- show up 5 times, and every total or count you calculate after that would be multiplied by
-- the number of items. This model fixes that before it causes problems downstream.
--
-- avg_unit_price is added here to give a quick sense of the average price per unit sold on
-- each order. It uses nullif to avoid dividing by zero on orders with no quantity recorded.

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
        count(order_item_id)                                    as order_item_count,
        sum(quantity)                                           as total_quantity,
        sum(unit_price * quantity)                              as gross_item_revenue,
        sum(discount_amount)                                    as total_item_discount_amount,
        sum(total_price)                                        as net_item_revenue,
        sum(unit_price * quantity) / nullif(sum(quantity), 0)   as avg_unit_price
    from order_items
    group by order_id
)

select
    order_id,
    order_item_count,
    total_quantity,
    gross_item_revenue,
    total_item_discount_amount,
    net_item_revenue,
    avg_unit_price
from summary