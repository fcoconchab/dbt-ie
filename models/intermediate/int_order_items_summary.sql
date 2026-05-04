with order_items as (
    select
        order_id,
        order_item_id,
        quantity,
        total_price
    from {{ ref('stg_order_items') }}
),

summary as (
    select
        order_id,
        count(order_item_id)    as n_items,
        sum(quantity)           as total_quantity,
        sum(total_price)        as total_items_price
    from order_items
    group by order_id
)

select * from summary