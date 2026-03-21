with

customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

order_counts as (

    select
        customer_id,
        count(*) as lifetime_order_count

    from orders
    group by 1

),

segmented as (

    select
        customers.customer_id,
        case
            when order_counts.lifetime_order_count >= 10 then 'VIP'
            when order_counts.lifetime_order_count >= 3  then 'REGULAR'
            else                                              'NEW'
        end as segment_code,
        order_counts.lifetime_order_count

    from customers
    left join order_counts using (customer_id)

)

select * from segmented
