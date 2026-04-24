select
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    age,
    gender,
    country,
    state,
    city,
    registration_date,
    customer_segment,
    total_orders,
    total_spent,
    is_active
from {{ source('raw', 'customers') }}
