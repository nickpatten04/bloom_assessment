SELECT
    subscription_id,
    organization_id,
    UPPER(TRIM(plan_id)) AS plan_id,
    seats,
    mrr_amount,
    UPPER(TRIM(billing_interval)) AS billing_interval,
    started_at::TIMESTAMP AS started_at,
    ended_at::TIMESTAMP as ended_at,
    UPPER(TRIM(change_reason)) AS change_reason
FROM {{ ref('subscriptions') }}