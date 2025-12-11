# dbt + DuckDB Docker Image for Argo Workflows
FROM python:3.11-slim

WORKDIR /dbt

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Copy dependency files first (for better caching)
COPY pyproject.toml .

# Install dependencies with uv
RUN uv sync --no-dev --frozen 2>/dev/null || uv pip install --system dbt-core dbt-duckdb duckdb

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
