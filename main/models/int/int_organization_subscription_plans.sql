SELECT
    {{ dbt_utils.generate_surrogate_key(['o.organization_id', 's.subscription_id', 'p.plan_id']) }} AS organization_subscription_plan_id,
    o.organization_id,
    o.organization_name,
    o.organization_business_os_type,
    o.organization_industry,
    o.organization_employee_count,
    o.organization_size_cohort,
    o.organization_status,
    o.organization_plan_name,
    o.organization_is_churned,
    s.subscription_id,
    s.seats AS subscription_seats,
    s.mrr_amount AS subscription_mrr_amount,
    s.billing_interval AS subscription_billing_interval,
    s.change_reason AS subscription_change_reason,
    p.plan_id,
    p.plan_name,
    p.base_price AS plan_base_price,
    p.per_seat_price AS plan_per_seat_price,
    s.started_at AS subscription_started_at,
    COALESCE(s.ended_at, '9999-12-31'::TIMESTAMP) AS subscription_ended_at
FROM {{ ref('int_organizations') }} o
LEFT JOIN {{ ref('stg_subscriptions') }} s ON s.organization_id = o.organization_id
LEFT JOIN {{ ref('stg_plans') }} p ON p.plan_id = s.plan_id
