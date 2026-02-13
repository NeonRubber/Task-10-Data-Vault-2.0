-- Test uniqueness of composite key (customer_sk, valid_from)
select
    customer_sk,
    valid_from
from {{ ref('dim_customer') }}
group by customer_sk, valid_from
having count(*) > 1
