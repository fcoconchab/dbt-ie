select
    *
from {{ source('raw', 'returns') }}
