with orders as (
    select
        order_id,
        customer_id,
        order_date,
        status,
        subtotal,
        tax_amount,
        shipping_cost,
        discount_amount,
        total_amount,
        payment_method
    from {{ ref('stg_orders') }}
),

order_items_summary as (
    select
        order_id,
        n_items,
        total_quantity,
        total_items_price
    from {{ ref('int_order_items_summary') }}
),

order_shipping as (
    select
        order_id,
        ship_date,
        estimated_delivery,
        actual_delivery,
        carrier,
        shipping_method,
        shipping_status,
        days_to_ship,
        is_late
    from {{ ref('int_order_shipping') }}
),

final as (
    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        orders.status,
        orders.subtotal,
        orders.tax_amount,
        orders.shipping_cost,
        orders.discount_amount,
        orders.total_amount,
        orders.payment_method,
        order_items_summary.n_items,
        order_items_summary.total_quantity,
        order_items_summary.total_items_price,
        order_shipping.ship_date,
        order_shipping.estimated_delivery,
        order_shipping.actual_delivery,
        order_shipping.carrier,
        order_shipping.shipping_method,
        order_shipping.shipping_status,
        order_shipping.days_to_ship,
        order_shipping.is_late
    from orders
    left join order_items_summary using (order_id)
    left join order_shipping using (order_id)
)

select * from final
