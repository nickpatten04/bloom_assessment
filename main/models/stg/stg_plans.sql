SELECT
    UPPER(TRIM(plan_id)) AS plan_id,
    UPPER(TRIM(plan_name)) AS plan_name,
    base_price,
    per_seat_price
FROM {{ ref('plans') }}