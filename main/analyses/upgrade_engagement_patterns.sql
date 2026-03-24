WITH months AS(
    SELECT
        organization_id,
        month,
        subscription_change_reason,
        num_events,
        num_rocks,
        num_issues,
        num_meetings,
        num_scorecards,
        num_todos,
        num_headlines,
        MAX(CASE WHEN subscription_change_reason = 'UPGRADE' THEN 1 ELSE 0 END)
            OVER(
                PARTITION BY organization_id
                ORDER BY month
                ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING
            ) AS is_within_3_months_of_upgrade
    FROM {{ ref('monthly_organization_activity') }}
    WHERE NOT organization_is_churned_in_month
),
groupings AS (
    SELECT
        organization_id,
        month,
        subscription_change_reason,
        num_events,
        num_rocks,
        num_issues,
        num_meetings,
        num_scorecards,
        num_todos,
        num_headlines,
        is_within_3_months_of_upgrade,
        CASE
            WHEN subscription_change_reason = 'UPGRADE' THEN 'UPGRADE MONTH'
            WHEN is_within_3_months_of_upgrade = 1 THEN 'PRE UPGRADE 3 MONTHS'
            ELSE 'BASELINE'
        END AS period
    FROM months
)
SELECT
    period,
    COUNT(*) AS num_months,
    AVG(num_events) AS avg_total_events,
    AVG(num_rocks) AS avg_rocks,
    AVG(num_issues) AS avg_issues,
    AVG(num_meetings) AS avg_meetings,
    AVG(num_scorecards) AS avg_scorecards,
    AVG(num_todos) AS avg_todos,
    AVG(num_headlines) AS avg_headlines 
FROM groupings
GROUP BY 1