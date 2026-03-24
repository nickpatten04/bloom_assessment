SELECT
    event_id,
    organization_id,
    user_id,
    UPPER(TRIM(feature_category)) AS feature_category,
    UPPER(TRIM(event_type)) AS event_type,
    event_date,
    event_timestamp
FROM {{ ref('activity_events') }}