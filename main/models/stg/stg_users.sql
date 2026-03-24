SELECT
    u.user_id,
    u.organization_id,
    UPPER(TRIM(u.user_name)) AS user_name,
    UPPER(TRIM(u.role)) AS role,
    u.is_registered,
    u.created_at::TIMESTAMP AS created_at,
    u.last_active_at::TIMESTAMP AS last_active_at
FROM {{ ref('users') }} u

