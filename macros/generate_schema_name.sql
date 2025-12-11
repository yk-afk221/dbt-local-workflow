{% macro generate_schema_name(custom_schema_name, node) -%}
    {#-
        カスタムスキーマ名を生成するマクロ（dbtデフォルトをオーバーライド）

        dbtのデフォルト動作:
            {target.schema}_{custom_schema_name}
            例: dev_sandbox_staging

        このマクロでの動作:
            - prd/prd_marts: custom_schema_nameをそのまま使用
            - dev/ci: {target.schema}_{custom_schema_name}

        BigQuery環境でも同様の動作:
            - 本番: staging, marts などのスキーマ名をそのまま使用
            - 開発: dev_sandbox_staging, ci_12345_staging など

        Args:
            custom_schema_name: models/で設定した+schema値
            node: dbtノード情報

        Returns:
            生成されたスキーマ名
    -#}

    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- elif target.name in ['prd', 'prd_marts'] -%}
        {# 本番環境: カスタムスキーマ名をそのまま使用 #}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {# 開発/CI環境: ターゲットスキーマ + カスタムスキーマ #}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
