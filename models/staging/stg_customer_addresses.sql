select
    *
from {{ source('raw', 'customer_addresses') }}
