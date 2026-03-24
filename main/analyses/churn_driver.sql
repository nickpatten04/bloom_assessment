WITH most_recent_months AS (
    SELECT
        organization_id,
        SUM(mom_total_mrr_delta) AS total_mrr_delta
    FROM {{ ref('monthly_organization_activity') }} moa
    WHERE organization_is_churned AND NOT organization_is_churned_in_month
    AND month >= DATE_TRUNC('month', organization_churned_at) - INTERVAL '6 months'
    GROUP BY 1
)
SELECT
    COUNT(CASE WHEN total_mrr_delta <= 0 THEN organization_id END)*1.0 / COUNT(organization_id) AS zero_growth_organization_percentage
FROM most_recent_months