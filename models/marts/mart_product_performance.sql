with order_items as (
    select
        order_item_id,
        product_id,
        quantity,
        total_price
    from {{ ref('stg_order_items') }}
),

products as (
    select
        product_id,
        product_name,
        category_name
    from {{ ref('dim_products') }}
),

joined as (
    select
        order_items.order_item_id,
        order_items.quantity,
        order_items.total_price,
        products.product_id,
        products.product_name,
        products.category_name
    from order_items
    left join products using (product_id)
),

final as (
    select
        product_id,
        product_name,
        category_name,
        sum(quantity)    as total_quantity_sold,
        sum(total_price) as total_revenue
    from joined
    group by product_id, product_name, category_name
)

select * from final