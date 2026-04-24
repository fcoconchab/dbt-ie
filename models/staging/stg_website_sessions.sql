select
    *
from {{ source('raw', 'website_sessions') }}
