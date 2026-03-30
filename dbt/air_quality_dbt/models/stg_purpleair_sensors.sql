select
  *
from {{ source('raw', 'purpleair_sensors') }}
