with orders as (
    select
        order_id,
        customer_id,
        order_date,
        status,
        total_amount
    from {{ ref('stg_orders') }}
),

customers as (
    select
        customer_id,
        customer_segment,
        country
    from {{ ref('stg_customers') }}
),

final as (
    select
        orders.order_id,
        orders.order_date,
        orders.status,
        orders.total_amount,
        orders.customer_id,
        customers.customer_segment,
        customers.country
    from orders
    left join customers using (customer_id)
)

select * from final