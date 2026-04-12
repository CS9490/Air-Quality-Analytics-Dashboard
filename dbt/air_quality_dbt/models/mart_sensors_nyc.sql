 {{
  config(
    materialized='table',
    cluster_by=['boro_name']
  )
}}

with distinct_sensors as (
    select distinct(sensor_index)
    from {{ ref('int_sensors_hourly_with_borough') }}
    where boro_name is not null
)

select
  sensor_index,
  og.name,
  og.altitude,
  og.boro_name,
  og.location_point
from distinct_sensors
left join {{ ref('int_sensors_hourly_with_borough') }} og
using (sensor_index)
