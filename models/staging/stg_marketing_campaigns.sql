select
    *
from {{ source('raw', 'marketing_campaigns') }}
