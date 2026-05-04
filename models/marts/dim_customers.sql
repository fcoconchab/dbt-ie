with customers as (
    select
        customer_id,
        first_name,
        last_name,
        email,
        country,
        customer_segment,
        segment_id
    from {{ ref('int_customers') }}
)

select * from customers
