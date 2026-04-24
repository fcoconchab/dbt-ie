select
    *
from {{ source('raw', 'shipping') }}
