 {{
  config(
    materialized='table',
    partition_by={
      'field': 'pulled_date',
      'data_type': 'date'
    },
    cluster_by=['sensor_index']
  )
}}

select
  *,
  date(pulled_hour) as pulled_date
from {{ ref('int_purpleair_sensors_ts_mapped_deduped') }}
