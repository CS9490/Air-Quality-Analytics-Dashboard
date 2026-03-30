{{ config(materialized='view') }}

with base as (
  select
    *,
    timestamp_seconds(safe_cast(last_modified as int64)) as last_modified_ts,
    timestamp_seconds(safe_cast(date_created as int64)) as created_at_ts,
    timestamp_seconds(safe_cast(last_seen as int64)) as last_seen_ts,
    safe_cast(pulled_at as timestamp) as pulled_at_ts
  from {{ ref('stg_purpleair_sensors') }}
),

hourly as (
  select
    *,
    timestamp_trunc(pulled_at_ts, hour) as pulled_hour
  from base
),

dedup as (
  select
    *,
    row_number() over (
      partition by sensor_index, pulled_hour
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
