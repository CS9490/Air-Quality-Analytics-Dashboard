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
  count(distinct sensor_index) as sensor_count,
  avg(pm2_5_atm) as avg_pm2_5_atm,
  datetime(pulled_hour, 'America/New_York') as pulled_hour_est,
  date(pulled_hour, 'America/New_York') as pulled_date
from {{ ref('int_sensors_hourly_with_borough') }}
  where boro_name is not null
  group by boro_name, pulled_hour_est, pulled_date