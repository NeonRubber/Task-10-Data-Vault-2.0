import os
from datetime import datetime
from airflow import DAG
from cosmos import DbtDag
from cosmos.constants import TestBehavior

from cosmos_config import project_config, profile_config, execution_config, render_config
from callbacks import send_telegram_failure, send_telegram_success

# DAG Definition
dag = DbtDag(
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=render_config,
    
    # DAG settings
    dag_id="retail_incremental_load",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",
    catchup=False,
    
    # Dbt Args
    operator_args={
        "full_refresh": False,
        "install_deps": False,
    },
    
    # Callbacks
    on_failure_callback=send_telegram_failure,
    on_success_callback=send_telegram_success
)