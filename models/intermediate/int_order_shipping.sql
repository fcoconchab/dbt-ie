with orders as (
    select
        order_id,
        order_date::date as order_date
    from {{ ref('stg_orders') }}
),

shipping as (
    select
        order_id,
        ship_date::date         as ship_date,
        estimated_delivery::date as estimated_delivery,
        actual_delivery::date   as actual_delivery,
        carrier,
        shipping_method,
        shipping_status
    from {{ ref('stg_shipping') }}
),

joined as (
    select
        orders.order_id,
        orders.order_date,
        shipping.ship_date,
        shipping.estimated_delivery,
        shipping.actual_delivery,
        shipping.carrier,
        shipping.shipping_method,
        shipping.shipping_status,
        datediff('day', orders.order_date, shipping.ship_date)
            as days_to_ship,
        shipping.actual_delivery > shipping.estimated_delivery
            as is_late
    from orders
    left join shipping using (order_id)
)

select * from joined

