SELECT
    organization_business_os_type,
    SUM(total_revenue) AS total_revenue,
    SUM(num_users) AS total_users,
    SUM(total_events) AS total_events,
    SUM(total_issues) AS total_issues,
    SUM(total_revenue) / SUM(num_users) AS revenue_per_user,
    SUM(total_revenue) / SUM(total_events) AS revenue_per_event,
    SUM(total_events) / SUM(num_users) AS events_per_user,
    SUM(total_issues) / SUM(num_users) AS issues_per_user
FROM {{ ref('organization_segments') }}
GROUP BY 1