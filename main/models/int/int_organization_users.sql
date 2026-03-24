SELECT
    o.organization_id,
    o.organization_name,
    o.organization_business_os_type,
    o.organization_industry,
    o.organization_employee_count,
    o.organization_size_cohort,
    o.organization_status,
    o.organization_plan_name,
    o.organization_is_churned,
    u.user_id,
    u.user_full_name,
    u.user_first_name,
    u.user_last_name,
    u.user_role,
    u.user_is_registered,
    u.user_created_at,
    u.user_last_active_at,
    o.organization_created_at,
    o.organization_churned_at
FROM {{ ref('int_organizations') }} o
LEFT JOIN {{ ref('int_users') }} u ON o.organization_id = u.organization_id