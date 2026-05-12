-- Grain: one row per order_id
-- Business question: For each order, how many payment attempts were made, how much was actually
--                    collected, and what is the overall payment status?
-- Purpose: Aggregate payment records from stg_payments to one row per order with counts,
--          amounts, and business-level status flags so other models do not have to touch
--          the raw payments table directly.
--
-- Only completed payments count toward total_paid_amount. Refunded or failed payments did not
-- bring in real money so including them would overstate what was actually collected.
--
-- If an order had a failed attempt followed by a successful one it still counts as paid.
-- The failed attempt is flagged through has_payment_issue because it shows the customer had
-- friction at checkout, which is useful for the support team even when the order ended up paid.
--
-- An order can have more than one payment record, for example a failed first attempt and a
-- successful retry. The model handles this by aggregating all records and comparing
-- payment_count to successful_payment_count to detect those cases.

with payments as (
    select
        payment_id,
        order_id,
        payment_method,
        amount,
        status
    from {{ ref('stg_payments') }}
),

summary as (
    select
        order_id,
        count(payment_id)                                               as payment_count,
        count(case when status = 'completed' then 1 end)                as successful_payment_count,
        sum(case when status = 'completed' then amount else 0 end)      as total_paid_amount,
        max(payment_method)                                             as primary_payment_method,
        case
            when sum(case when status = 'completed' then 1 else 0 end) > 0 then true
            else false
        end as has_successful_payment,
        case
            when count(payment_id) > sum(case when status = 'completed' then 1 else 0 end) then true
            else false
        end as has_payment_issue,
        case
            when count(payment_id) = 0 then 'unknown'
            when sum(case when status = 'completed' then 1 else 0 end) = count(payment_id) then 'paid'
            when sum(case when status = 'completed' then 1 else 0 end) > 0 then 'partially_paid'
            else 'unpaid'
        end as payment_status_summary
    from payments
    group by order_id
)

select
    order_id,
    payment_count,
    successful_payment_count,
    total_paid_amount,
    primary_payment_method,
    has_successful_payment,
    has_payment_issue,
    payment_status_summary
from summary