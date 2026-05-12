with customers as (
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
    from {{ ref('int_customers_enriched') }}
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
from customers