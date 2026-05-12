-- Grain: one row per customer_id
-- Business question: For each customer, what are their core attributes and segment information,
--                    in a clean, reusable form?
-- Purpose: Join cleaned customer data from stg_customers with the segments seed, adding friendly fields
--          like full_name and email_domain, to produce a standardized customer dimension used by marts
--          such as dim_customers and segment-level revenue models.

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
        customer_segments.segment_id
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
    segment_id
from merged