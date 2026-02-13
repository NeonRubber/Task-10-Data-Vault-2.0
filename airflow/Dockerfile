FROM apache/airflow:2.10.3-python3.11

USER root

# System dependencies (git needed for dbt deps)
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER airflow

# Install uv (Package Manager) as per Tech Spec
RUN pip install uv

# Copy dependency definition files
COPY pyproject.toml uv.lock /opt/airflow/

# Sync dependencies into a virtual environment (.venv)
# --frozen: use exact versions from uv.lock
# --no-cache: reduce image size
RUN uv sync --frozen --no-cache

# Add .venv/bin to PATH so we can run 'dbt' directly without full path
ENV PATH="/opt/airflow/.venv/bin:$PATH"