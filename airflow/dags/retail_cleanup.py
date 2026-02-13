import os
from datetime import datetime
from airflow import DAG
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from airflow.operators.bash import BashOperator
from callbacks import send_telegram_failure, send_telegram_success 
from utils.constants import SNOWFLAKE_CONN_ID 

# DAG Definition
with DAG(
    dag_id="retail_cleanup",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@weekly",
    catchup=False,
    default_args={
        "on_failure_callback": send_telegram_failure,
        "on_success_callback": send_telegram_success,
    }
) as dag:

    cleanup_task = SnowflakeOperator(
        task_id="cleanup_stale_data",
        snowflake_conn_id=SNOWFLAKE_CONN_ID,
        sql="DROP SCHEMA IF EXISTS retail_vault_dev.public_staging CASCADE;",
    )
    
    cleanup_task