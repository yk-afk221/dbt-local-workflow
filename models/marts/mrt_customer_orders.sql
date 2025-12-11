{{
    config(
        materialized='table'
    )
}}

/*
    Marts model: Customer Orders Summary

    顧客ごとの注文サマリーを集計

    Dependencies:
    - stg_customers
    - stg_orders
*/

with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

customer_orders as (

    select
        c.customer_id,
        c.customer_name,
        c.email,
        count(o.order_id) as total_orders,
        coalesce(sum(o.amount), 0) as total_amount,
        min(o.order_date) as first_order_date,
        max(o.order_date) as last_order_date

    from customers c
    left join orders o on c.customer_id = o.customer_id
    group by c.customer_id, c.customer_name, c.email

)

select * from customer_orders
