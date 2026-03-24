SELECT
    organization_id,
    UPPER(TRIM(organization_name)) AS organization_name,
    UPPER(TRIM(business_os_type)) AS business_os_type,
    UPPER(TRIM(industry)) AS industry,
    employee_count,
    UPPER(TRIM(status)) AS status,
    created_at::TIMESTAMP AS created_at,
    churned_at::TIMESTAMP AS churned_at
FROM {{ ref('organizations') }}