 {{
  config(
    materialized='table',
    partition_by={
      'field': 'pulled_at',
      'data_type': 'timestamp'
    },
    cluster_by=['location_type', 'sensor_index']
  )
}}

select
  * except (location_type),
  case when location_type = 0 then 'Outside' else 'Inside' end as location_type,
  timestamp_seconds(safe_cast(last_modified as int64)) as last_modified_ts,
  timestamp_seconds(safe_cast(date_created as int64)) as created_at_ts,
  timestamp_seconds(safe_cast(last_seen as int64)) as last_seen_ts,
  safe_cast(pulled_at as timestamp) as pulled_at_ts
from {{ source('raw', 'purpleair_sensors') }}