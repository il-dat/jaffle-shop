with

orders as (

    select * from {{ ref('stg_orders') }}

),

segments as (

    select * from {{ ref('dim_customer_segment') }}

),

joined as (

    select
        orders.order_id,
        orders.customer_id,
        segments.segment_code,
        orders.ordered_at,
        orders.order_total

    from orders
    inner join segments using (customer_id)

)

select * from joined
