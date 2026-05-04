with products as (
    select
        product_id,
        product_name,
        category_id,
        supplier_id,
        price,
        cost,
        sku,
        status,
        is_featured
    from {{ ref('stg_products') }}
),

categories as (
    select
        category_id,
        category_name
    from {{ ref('stg_categories') }}
),

joined as (
    select
        products.product_id,
        products.product_name,
        products.supplier_id,
        products.price,
        products.cost,
        products.sku,
        products.status,
        products.is_featured,
        categories.category_name
    from products
    left join categories using (category_id)
)

select * from joined

