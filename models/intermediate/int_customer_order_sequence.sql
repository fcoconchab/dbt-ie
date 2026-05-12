-- Grain: one row per order_id (with customer sequence context)
-- Business question: For each order, what number order is it for that customer and how long
--                    has it been since their previous order?
-- Purpose: Use window functions over stg_orders to number each customer's orders over time,
--          flag first orders, and calculate days between purchases, enabling repeat purchase
--          analysis and customer lifecycle tracking.
--
-- I included all orders regardless of status, including cancelled and refunded ones. A
-- cancelled order still represents a customer decision and affects the gap between purchases.
-- A customer who cancelled three orders before completing one is different from a first-time
-- buyer and the sequence should reflect that. Marts that only want completed orders can filter
-- by status themselves.
--
-- When two orders share the same date, the tie is broken by order_id as a secondary sort key.
-- It is not a perfect solution but it is consistent. The same query will always produce the
-- same result, which matters more than the tie-breaking logic being meaningful.
--
-- previous_order_date is null for a customer's first order because there was nothing before it.
-- days_since_previous_order is null for the same reason. This is expected, not a data problem.
--
-- customer_lifecycle_stage classifies each order into new, returning, or loyal based on where
-- it falls in the customer's sequence. It is defined here once so retention and CRM models
-- do not have to repeat the classification logic.

with orders as (
    select
        order_id,
        customer_id,
        order_date,
        status
    from {{ ref('stg_orders') }}
),

sequenced as (
    select
        order_id,
        customer_id,
        order_date,
        status,
        row_number() over (
            partition by customer_id
            order by order_date, order_id
        ) as customer_order_number,
        lag(order_date) over (
            partition by customer_id
            order by order_date, order_id
        ) as previous_order_date
    from orders
),

final as (
    select
        order_id,
        customer_id,
        order_date,
        status,
        customer_order_number,
        case when customer_order_number = 1 then true else false end as is_first_order,
        previous_order_date,
        datediff(
            'day',
            cast(previous_order_date as date),
            cast(order_date as date)
        ) as days_since_previous_order,
        case
            when customer_order_number = 1  then 'new'
            when customer_order_number <= 3 then 'returning'
            else 'loyal'
        end as customer_lifecycle_stage
    from sequenced
)

select
    order_id,
    customer_id,
    order_date,
    status,
    customer_order_number,
    is_first_order,
    previous_order_date,
    days_since_previous_order,
    customer_lifecycle_stage
from final