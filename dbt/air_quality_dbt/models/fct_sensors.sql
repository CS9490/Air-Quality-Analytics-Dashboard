{{ config(materialized='table') }}

with latest_sensor_rows as (
  select
    sensor_index,
    latitude,
    longitude,
    boro_name,
    row_number() over (
      partition by sensor_index
      order by pulled_at_ts desc, last_seen_ts desc
    ) as row_num
  from {{ ref('int_sensors_hourly_with_borough') }}
  where boro_name is not null
)

select
  sensor_index,
  latitude,
  longitude,
  boro_name
from latest_sensor_rows
where row_num = 1
