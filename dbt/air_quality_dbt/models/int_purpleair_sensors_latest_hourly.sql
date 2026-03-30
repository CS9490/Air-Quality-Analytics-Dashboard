{{ config(materialized='view') }}

with base as (
  select
    *,
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
  * except(_row_number)
from dedup
where _row_number = 1
