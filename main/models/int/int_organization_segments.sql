WITH total_revenue AS (
    SELECT
        organization_id,
        SUM(mrr_amount * {{ dbt.datediff('started_at', 'COALESCE(ended_at, current_date)', 'month') }}) AS total_revenue
    FROM {{ ref('stg_subscriptions') }} 
    GROUP BY 1
),
current_users AS (
    SELECT
        organization_id,
        COUNT(DISTINCT user_id) AS num_users,
        COUNT(CASE WHEN user_is_registered THEN user_id END) AS num_registered_users
    FROM {{ ref('int_organization_users') }}
    GROUP BY 1
)
SELECT
    moa.organization_business_os_type,
    moa.organization_industry,
    moa.organization_size_cohort,
    moa.organization_status_current,
    moa.organization_plan_name_current,
    SUM(tr.total_revenue) AS total_revenue,
    SUM(cu.num_users) AS total_users,
    SUM(cu.num_registered_users) AS total_registered_users,
    SUM(moa.num_events) AS total_events,
    SUM(moa.num_rocks) AS total_rocks,
    SUM(moa.num_issues) AS total_issues,
    SUM(moa.num_meetings) AS total_meetings,
    SUM(moa.num_scorecards) AS total_scorecards,
    SUM(moa.num_todos) AS total_todos,
    SUM(moa.num_headlines) AS total_headlines
FROM {{ ref('int_monthly_organization_activity') }} moa
LEFT JOIN total_revenue tr ON tr.organization_id = moa.organization_id
LEFT JOIN current_users cu ON cu.organization_id = moa.organization_id
GROUP BY 1, 2, 3, 4, 5