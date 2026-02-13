from cosmos.config import ProfileConfig, ProjectConfig, ExecutionConfig, RenderConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping
from cosmos.constants import TestBehavior

# Path constants
DBT_PROJECT_DIR = "/opt/airflow/dbt_core"
DBT_EXECUTABLE_PATH = "/opt/airflow/.venv/bin/dbt"

# Configuration

profile_config = ProfileConfig(
    profile_name="retail_vault",
    target_name="dev",
    profile_mapping=SnowflakeUserPasswordProfileMapping(
        conn_id="snowflake_default",
        profile_args={
            "database": "RETAIL_VAULT_DEV",
            "schema": "PUBLIC"
        },
    )
)

project_config = ProjectConfig(
    dbt_project_path=DBT_PROJECT_DIR,
)

execution_config = ExecutionConfig(
    dbt_executable_path=DBT_EXECUTABLE_PATH,
)

render_config = RenderConfig(
    dbt_deps=False,
    select=["path:models/staging", "path:models/raw_vault", "path:models/business_vault", "path:models/marts"],
    test_behavior=TestBehavior.AFTER_EACH,
    emit_datasets=False
)