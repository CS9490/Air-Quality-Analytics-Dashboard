{{ config(materialized='table') }}

with src as (
  select
    safe_cast(boro_code as int64) as boro_code,
    cast(boro_name as string) as boro_name,
    cast(the_geom_geojson as string) as the_geom_geojson
  from {{ source('raw', 'nyc_borough_boundaries') }}
)

select
  boro_code,
  boro_name,
  the_geom_geojson,
  coalesce(
    safe.st_geogfromgeojson(the_geom_geojson),
    safe.st_geogfromtext(the_geom_geojson)
  ) as boro_geog
from src
qualify row_number() over (
  partition by boro_code
  order by boro_name
) = 1
