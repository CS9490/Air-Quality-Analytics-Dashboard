{{ config(materialized='table') }}

select
    distinct(sensor_index),
    latitude,
    longitude,
    boro_name
  from {{ ref('int_sensors_hourly_with_borough') }}
  where boro_name is not null
