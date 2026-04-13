{{ config(materialized='view') }}

with hourly as (
  select
    *,
    timestamp_trunc(pulled_at_ts, hour) as pulled_hour
  from {{ ref('stg_purpleair_sensors') }}
  where location_type = 'Outside'
),

dedup as (
  select
    *,
    row_number() over (
      partition by sensor_index, last_seen
      order by pulled_at_ts desc
    ) as _row_number
  from hourly
)

select
  * except(_row_number),
  st_geogpoint(
    safe_cast(longitude as float64),
    safe_cast(latitude as float64)
  ) as location_point
from dedup
where _row_number = 1
