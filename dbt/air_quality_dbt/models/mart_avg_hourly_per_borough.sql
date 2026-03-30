 {{
  config(
    materialized='table',
    partition_by={
      'field': 'boro_name',
      'data_type': 'string'
    },
    cluster_by=['sensor_index']
  )
}}