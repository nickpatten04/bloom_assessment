WITH correlation_coefficients AS (
    SELECT 
        month,
        CORR(num_events, total_mrr_amount) AS correlation_coefficient
    FROM {{ ref('monthly_organization_activity') }}
    WHERE mom_total_mrr_delta != 0 AND NOT organization_is_churned_in_month
    GROUP BY 1
)
SELECT
    AVG(ABS(correlation_coefficient))
FROM correlation_coefficients;