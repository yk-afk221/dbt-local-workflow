{{
    config(
        materialized='view'
    )
}}

/*
    Staging model for orders

    Source: raw.orders
    - dev/ci環境: dev_rawスキーマから取得
    - prd環境: prd_rawスキーマから取得

    Transformations:
    - カラム名の標準化
    - 日付型への変換
*/

with source as (

    select * from {{ source('raw', 'orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        order_date,
        amount,
        status

    from source

)

select * from renamed
