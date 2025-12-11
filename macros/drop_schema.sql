{% macro drop_schema(schema_name) %}
    {#-
        指定したスキーマを削除するマクロ

        主にCI完了後の一時スキーマ（ci_{run_id}）の削除に使用

        Args:
            schema_name: 削除するスキーマ名

        Usage:
            dbt run-operation drop_schema --args '{"schema_name": "ci_12345"}'

        Note:
            BigQueryではDROP SCHEMA IF EXISTS ... CASCADEを使用
            DuckDBでは同様のDROP SCHEMAを使用
    -#}

    {% set drop_command %}
        DROP SCHEMA IF EXISTS {{ schema_name }} CASCADE
    {% endset %}

    {% do log("Dropping schema: " ~ schema_name, info=True) %}

    {% do run_query(drop_command) %}

    {% do log("Schema dropped successfully: " ~ schema_name, info=True) %}

{% endmacro %}
