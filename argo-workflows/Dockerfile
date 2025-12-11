# dbt + DuckDB Docker Image for Argo Workflows
FROM python:3.11-slim

WORKDIR /dbt

# Install dbt and DuckDB
RUN pip install --no-cache-dir \
    dbt-core \
    dbt-duckdb \
    duckdb

# Copy dbt project files
COPY dbt_project.yml .
COPY profiles.yml .
COPY models/ ./models/
COPY macros/ ./macros/
COPY seeds/ ./seeds/
COPY scripts/ ./scripts/

# Setup local environment (create schemas)
RUN python scripts/setup_local_env.py

# Default command
CMD ["dbt", "build", "--target", "dev"]
