SELECT
    user_id,
    organization_id,
    user_name AS user_full_name,
    SUBSTRING(user_name FROM '^\w+') AS user_first_name,
    SUBSTRING(user_name FROM '\w+$') AS user_last_name,
    role AS user_role,
    is_registered AS user_is_registered,
    created_at AS user_created_at,
    last_active_at AS user_last_active_at
FROM {{ ref('stg_users') }}