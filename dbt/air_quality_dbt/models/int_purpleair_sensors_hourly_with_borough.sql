{{ config(materialized='view') }}

select
  s.*,
  b.boro_code,
  b.boro_name
from {{ ref('int_purpleair_sensors_ts_deduped') }} s
left join {{ ref('dim_nyc_boroughs') }} b
  on st_within(s.location_point, b.boro_geog)