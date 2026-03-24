WITH mrr AS (
    SELECT
        DATE_TRUNC('month', subscription_started_at)::DATE AS subscription_started_month,
        DATE_TRUNC('month', subscription_ended_at)::DATE AS subscription_ended_month,
        organization_id,
        plan_name AS plan_name,
        SUM(subscription_mrr_amount) AS total_mrr_amount,
        SUM(subscription_seats) AS total_seats
    FROM {{ ref('int_organization_subscription_plans') }}
    GROUP BY 1, 2, 3, 4
),
subscription_change AS (
    SELECT
        DATE_TRUNC('month', subscription_started_at)::DATE AS subscription_month,
        organization_id,
        subscription_change_reason
    FROM {{ ref('int_organization_subscription_plans') }}
),
events AS (
    SELECT
        DATE_TRUNC('month', event_timestamp)::DATE AS event_month,
        organization_id,
        COUNT(*) AS num_events,
        COUNT(CASE WHEN event_type IN ('ROCK_CREATED', 'ROCK_UPDATED') THEN 1 END) AS num_rocks,
        COUNT(CASE WHEN event_type = 'ISSUE_CREATED' THEN 1 END) AS num_issues,
        COUNT(CASE WHEN event_type = 'MEETING_CREATED' THEN 1 END) AS num_meetings,
        COUNT(CASE WHEN event_feature_category = 'SCORECARDS' THEN 1 END) AS num_scorecards,
        COUNT(CASE WHEN event_feature_category = 'TODOS' THEN 1 END) AS num_todos,
        COUNT(CASE WHEN event_feature_category = 'HEADLINES' THEN 1 END) AS num_headlines
    FROM {{ ref('int_user_organization_activity_events') }}
    GROUP BY 1, 2
),
organizations AS (
    SELECT
        organization_id,
        organization_name,
        organization_business_os_type,
        organization_industry,
        organization_employee_count,
        organization_size_cohort,
        organization_status,
        organization_plan_name,
        organization_is_churned,
        organization_churned_at
    FROM {{ ref('int_organization_users') }}
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),
pre_user_event_organization_activity AS (
    SELECT 
        DATE_TRUNC('month', subscription_started_at)::DATE AS month,
        o.organization_id,
        o.organization_name,
        o.organization_business_os_type,
        o.organization_industry,
        o.organization_employee_count,
        o.organization_size_cohort,
        o.organization_status AS organization_status_current,
        o.organization_plan_name AS organization_plan_name_current,
        osp.subscription_change_reason,
        o.organization_is_churned,
        o.organization_churned_at::DATE AS organization_churned_at,
        CASE 
            WHEN DATE_TRUNC('month', o.organization_churned_at)::DATE = DATE_TRUNC('month', subscription_started_at)::DATE THEN TRUE
            ELSE FALSE
        END AS organization_is_churned_in_month,
        osp.plan_name AS organization_plan_name,
        MAX(osp.subscription_mrr_amount) AS total_mrr_amount,
        MAX(osp.subscription_seats) AS total_seats,
        0 AS num_events,
        0 AS num_rocks,
        0 AS num_issues,
        0 AS num_meetings,
        0 AS num_scorecards,
        0 AS num_todos,
        0 AS num_headlines
    FROM {{ ref('int_organization_subscription_plans') }} osp
    LEFT JOIN organizations o ON osp.organization_id = o.organization_id
    WHERE DATE_TRUNC('month', subscription_started_at)::DATE < (SELECT MIN(DATE_TRUNC('month',event_timestamp))::DATE FROM {{ ref('int_user_organization_activity_events') }} _uoae WHERE _uoae.organization_id = osp.organization_id)
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
),
monthly_organization_activity AS (
    SELECT
        COALESCE(e.event_month, m.subscription_started_month) AS month,
        o.organization_id,
        o.organization_name,
        o.organization_business_os_type,
        o.organization_industry,
        o.organization_employee_count,
        o.organization_size_cohort,
        o.organization_status AS organization_status_current,
        o.organization_plan_name AS organization_plan_name_current,
        sc.subscription_change_reason,
        o.organization_is_churned,
        o.organization_churned_at::DATE AS organization_churned_at,
        CASE 
            WHEN DATE_TRUNC('month', o.organization_churned_at)::DATE = COALESCE(e.event_month, m.subscription_started_month) THEN TRUE
            ELSE FALSE
        END AS organization_is_churned_in_month,
        m.plan_name AS organization_plan_name,
        MAX(m.total_mrr_amount) AS total_mrr_amount,
        MAX(m.total_seats) AS total_seats,
        SUM(e.num_events) AS num_events,
        SUM(e.num_rocks) AS num_rocks,
        SUM(e.num_issues) AS num_issues,
        SUM(e.num_meetings) AS num_meetings,
        SUM(e.num_scorecards) AS num_scorecards,
        SUM(e.num_todos) AS num_todos,
        SUM(e.num_headlines) AS num_headlines
    FROM mrr m 
    FULL JOIN events e ON (e.event_month >= m.subscription_started_month AND e.event_month < m.subscription_ended_month) AND m.organization_id = e.organization_id
    LEFT JOIN organizations o ON o.organization_id = COALESCE(m.organization_id, e.organization_id)
    LEFT JOIN subscription_change sc ON sc.organization_id = COALESCE(m.organization_id, e.organization_id) AND sc.subscription_month = COALESCE(e.event_month, m.subscription_started_month)
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
)
SELECT
    month,
    organization_id,
    organization_name,
    organization_business_os_type,
    organization_industry,
    organization_employee_count,
    organization_size_cohort,
    organization_status_current,
    organization_plan_name_current,
    subscription_change_reason,
    organization_is_churned,
    organization_churned_at,
    CASE
        WHEN organization_is_churned_in_month = FALSE AND organization_status_current = 'CHURNED' THEN 'ACTIVE'
        ELSE organization_status_current
    END AS organization_status,
    organization_is_churned_in_month,
    organization_plan_name,
    total_mrr_amount,
    total_seats,
    num_events,
    num_rocks,
    num_issues,
    num_meetings,
    num_scorecards,
    num_todos,
    num_headlines
FROM monthly_organization_activity

UNION 

SELECT 
    month,
    organization_id,
    organization_name,
    organization_business_os_type,
    organization_industry,
    organization_employee_count,
    organization_size_cohort,
    organization_status_current,
    organization_plan_name_current,
    subscription_change_reason,
    organization_is_churned,
    organization_churned_at,
    CASE
        WHEN organization_is_churned_in_month = FALSE AND organization_status_current = 'CHURNED' THEN 'ACTIVE'
        ELSE organization_status_current
    END AS organization_status,
    organization_is_churned_in_month,
    organization_plan_name,
    total_mrr_amount,
    total_seats,
    num_events,
    num_rocks,
    num_issues,
    num_meetings,
    num_scorecards,
    num_todos,
    num_headlines
FROM pre_user_event_organization_activity