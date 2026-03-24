WITH business_os_type AS (
    SELECT
        organization_business_os_type,
        SUM(total_revenue) AS total_revenue
    FROM {{ ref('organization_segments') }}
    GROUP BY 1
),
industry AS (
    SELECT
        organization_industry,
        SUM(total_revenue) AS total_revenue
    FROM {{ ref('organization_segments') }}
    GROUP BY 1
),
size_cohort AS (
    SELECT
        organization_size_cohort,
        SUM(total_revenue) AS total_revenue
    FROM {{ ref('organization_segments') }}
    GROUP BY 1
),
plan_name_current AS (
     SELECT
        organization_plan_name_current,
        SUM(total_revenue) AS total_revenue
    FROM {{ ref('organization_segments') }}
    GROUP BY 1
),
unioned_revenue AS (
    SELECT
        dimension_name,
        dimension_value,
        total_revenue,
        ROW_NUMBER() OVER(PARTITION BY dimension_name ORDER BY total_revenue DESC) AS rn
    FROM (
        SELECT
            'BUSINESS OS TYPE' AS dimension_name,
            organization_business_os_type AS dimension_value,
            total_revenue
        FROM business_os_type
        UNION ALL
        SELECT
            'INDUSTRY' AS dimension_name,
            organization_industry AS dimension_value,
            total_revenue
        FROM industry
        UNION ALL
        SELECT
            'SIZE COHORT' AS dimension_name,
            organization_size_cohort AS dimension_value,
            total_revenue
        FROM size_cohort
        UNION ALL
        SELECT
            'CURRENT PLAN NAME' AS dimension_name,
            organization_plan_name_current AS dimension_value,
            total_revenue
        FROM plan_name_current
    )
)
SELECT
    dimension_name,
    dimension_value,
    total_revenue
FROM unioned_revenue
WHERE rn = 1