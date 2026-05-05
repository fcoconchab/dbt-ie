with orders as (
    select
        order_id,
        customer_id,
        total_amount
    from {{ ref('mart_orders') }}
),

customers as (
    select
        customer_id,
        customer_segment
    from {{ ref('dim_customers') }}
),

joined as (
    select
        orders.order_id,
        orders.total_amount,
        customers.customer_segment
    from orders
    left join customers using (customer_id)
),

final as (
    select
        customer_segment,
        count(order_id)     as number_of_orders,
        sum(total_amount)   as total_revenue,
        avg(total_amount)   as avg_order_value
    from joined
    group by customer_segment
)

select * from final