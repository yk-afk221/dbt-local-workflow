{{
    config(
        materialized='table'
    )
}}

/*
    Marts model: Daily Orders Summary

    日別の注文サマリーを集計

    Dependencies:
    - stg_orders
*/

with orders as (

    select * from {{ ref('stg_orders') }}

),

daily_orders as (

    select
        order_date,
        count(order_id) as order_count,
        sum(amount) as total_amount,
        avg(amount) as avg_amount,
        count(distinct customer_id) as unique_customers

    from orders
    group by order_date

)

select * from daily_orders
order by order_date
