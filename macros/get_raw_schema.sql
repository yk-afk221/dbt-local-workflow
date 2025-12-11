{% macro get_raw_schema() %}
    {#-
        RAW層のスキーマ名を取得するマクロ

        Returns:
            - dev/ci ターゲット: 'dev_raw'
            - prd/prd_marts ターゲット: 'prd_raw'

        Usage:
            {{ get_raw_schema() }}

        BigQuery環境では:
            - dev_raw: テスト用データセット
            - prd_raw: 本番データセット
    -#}
    {%- if target.name in ['dev', 'ci'] -%}
        dev_raw
    {%- else -%}
        prd_raw
    {%- endif -%}
{% endmacro %}
