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

with cte as (
  select
  sensor_index,
  avg(pm2_5_atm) as avg_pm2_5_atm,
  datetime(pulled_hour, 'America/New_York') as pulled_hour_est,
  date(pulled_hour, 'America/New_York') as pulled_date
from {{ ref('int_sensors_hourly_with_borough') }}
where boro_name is not null
group by sensor_index, pulled_hour_est, pulled_date
)

-- used to map sensors with heatmap style map, but not added to dashboard, so commented out for now
select cte.* 
  -- ,st_geogpoint(
  --   safe_cast(fct_sensors.longitude as float64),
  --   safe_cast(fct_sensors.latitude as float64)
  -- ) as location_point
from cte
-- left join {{ ref('fct_sensors') }} fct_sensors
-- on cte.sensor_index = fct_sensors.sensor_index
