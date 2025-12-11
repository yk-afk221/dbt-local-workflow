{{
    config(
        materialized='view'
    )
}}

/*
    Staging model for customers

    Source: raw.customers
    - dev/ci環境: dev_rawスキーマから取得
    - prd環境: prd_rawスキーマから取得

    Transformations:
    - カラム名の標準化
    - データ型の明示
*/

with source as (

    select * from {{ source('raw', 'customers') }}

),

renamed as (

    select
        customer_id,
        customer_name,
        email,
        created_at,
        updated_at

    from source

)

select * from renamed
