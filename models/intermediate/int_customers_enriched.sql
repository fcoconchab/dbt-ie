-- Grain: one row per customer_id
-- Business question: For each customer, what are their core attributes and segment information
--                    in a clean, reusable form?
-- Purpose: Join stg_customers to the segments seed to add segment_id, and derive full_name
--          and email_domain so downstream models do not have to repeat those calculations.
--
-- I kept customers even when their segment does not match anything in the seed. Dropping them
-- would mean losing real people from every downstream model silently, which is worse than
-- keeping them and flagging the problem. is_segment_matched makes the issue visible so it
-- can be investigated without breaking anything downstream.
--
-- email_domain is derived here and not in staging because it does not exist in the raw data.
-- Staging should pass through what is there. Derived fields belong in the intermediate layer.

with customers as (
    select
        customer_id,
        first_name,
        last_name,
        email,
        country,
        customer_segment
    from {{ ref('stg_customers') }}
),

customer_segments as (
    select
        segment_id,
        customer_segment
    from {{ ref('segments') }}
),

merged as (
    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customers.first_name || ' ' || customers.last_name as full_name,
        customers.email,
        split_part(customers.email, '@', 2)                as email_domain,
        customers.country,
        customers.customer_segment,
        customer_segments.segment_id,
        case
            when customer_segments.segment_id is not null then true
            else false
        end as is_segment_matched
    from customers
    left join customer_segments using (customer_segment)
)

select
    customer_id,
    first_name,
    last_name,
    full_name,
    email,
    email_domain,
    country,
    customer_segment,
    segment_id,
    is_segment_matched
from merged