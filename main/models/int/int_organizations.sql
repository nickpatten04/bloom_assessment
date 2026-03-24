WITH current_info AS (
    SELECT 
        organization_id,
        plan_id
    FROM (
        SELECT
            organization_id,
            plan_id,
            ROW_NUMBER() OVER(PARTITION BY organization_id ORDER BY started_at DESC) AS rn
        FROM {{ ref('stg_subscriptions') }} s
    ) rn WHERE rn = 1
)
SELECT
    o.organization_id,
    o.organization_name,
    o.business_os_type AS organization_business_os_type,
    o.industry AS organization_industry,
    o.employee_count AS organization_employee_count,
    CASE
        WHEN o.employee_count BETWEEN 1 AND 10 THEN 'VERY SMALL'
        WHEN o.employee_count BETWEEN 11 AND 25 THEN 'SMALL'
        WHEN o.employee_count BETWEEN 26 AND 50 THEN 'MEDIUM'
        WHEN o.employee_count BETWEEN 51 AND 100 THEN 'LARGE'
        WHEN o.employee_count > 100 THEN 'VERY LARGE'
    END AS organization_size_cohort,
    CASE 
        WHEN o.churned_at IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS organization_is_churned,
    o.status AS organization_status,
    ci.plan_id AS organization_plan_id,
    p.plan_name AS organization_plan_name,
    o.created_at AS organization_created_at,
    o.churned_at AS organization_churned_at
FROM {{ ref('stg_organizations') }} o
LEFT JOIN current_info ci ON ci.organization_id = o.organization_id
LEFT JOIN {{ ref('stg_plans') }} p ON p.plan_id = ci.plan_id