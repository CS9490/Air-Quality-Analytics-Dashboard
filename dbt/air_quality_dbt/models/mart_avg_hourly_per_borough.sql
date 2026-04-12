 {{
  config(
    materialized='table',
    partition_by={
      'field': 'pulled_date',
      'data_type': 'date'
    },
    cluster_by=['boro_name']
  )
}}

select
  boro_name,
  pulled_hour,
  date(pulled_hour) as pulled_date,
  avg(pm1_0_atm) as avg_pm1_0_atm,
  avg(pm2_5_atm) as avg_pm2_5_atm,
  avg(pm10_0_atm) as avg_pm10_0_atm,
  boro_geog
from {{ ref('int_sensors_hourly_with_borough') }}
where boro_name is not null
group by boro_name, pulled_hour, pulled_date