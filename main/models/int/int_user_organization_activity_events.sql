SELECT 
    ae.event_id,
    ae.event_type,
    CASE
        WHEN event_type LIKE 'MEETING_%' THEN 'MEETINGS'
        WHEN event_type LIKE 'ROCK_%' THEN 'ROCKS'
        WHEN event_type LIKE 'HEADLINE_%' THEN 'HEADLINES'
        WHEN event_type LIKE 'ISSUE_%' THEN 'ISSUES'
        WHEN event_type LIKE 'SCORECARD_%' THEN 'SCORECARDS'
        WHEN event_type LIKE 'TODO_%' THEN 'TODOS'
    END AS event_feature_category,
    u.user_id,
    u.user_full_name,
    u.user_first_name,
    u.user_last_name,
    u.user_role,
    u.user_is_registered,
    o.organization_id,
    o.organization_name,
    o.organization_business_os_type,
    o.organization_industry,
    o.organization_employee_count,
    o.organization_size_cohort,
    o.organization_status,
    o.organization_is_churned,
    u.user_created_at,
    u.user_last_active_at,
    o.organization_created_at,
    o.organization_churned_at,
    ae.event_timestamp
FROM {{ ref('stg_activity_events') }} ae
LEFT JOIN {{ ref('int_users') }} u ON u.user_id = ae.user_id AND u.organization_id = ae.organization_id
LEFT JOIN {{ ref('int_organizations') }} o ON o.organization_id = ae.organization_id