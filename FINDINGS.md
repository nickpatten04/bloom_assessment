# Overview

For this assessment, I decided to go with a postgres database and my engine. After bringing in the files provided and running them as seeds, I wrapped each in a staging model. I tried to keep the cleaning light here and stick to what I though was necessary. This resulted in me standardizing text fields using UPPER() and TRIM() and converting date to timestamps.

The heavy lifting was done in the intermediate layer. I wanted this layer to serve as the backbone for the analysis, reconciling any 1:M/M:M relationships in the dataset and doing more advanced calculations and transformations.

From here, I created two clean and simple mart level models to answer the questions posed in the assessment.

# Findings

## How do activity levels correlate with MRR (Monthly Recurring Revenue) changes?

I ran a simple correlation analysis to determine the linear coefficient between the number of events and the total MRR amount on a month-to-month basis. I found that for all of the months of data we have, the average correlation coefficient was .8, inidicating that there is a strong positive relationship between usage (number of events) and increased MRR.

```WITH correlation_coefficients AS (
    SELECT 
        month,
        CORR(num_events, total_mrr_amount) AS correlation_coefficient
    FROM "postgres"."bloom"."monthly_organization_activity"
    WHERE mom_total_mrr_delta != 0 AND NOT organization_is_churned_in_month
    GROUP BY 1
)
SELECT
    AVG(ABS(correlation_coefficient))
FROM correlation_coefficients;
```

## What early warning signs indicate churn risk?

To answer this question I wanted to analyze growth over the period of time before churn. For this question, I took the sum of the month-over-month delta for each over the organizations for their last 6 months, exluding the month they churned (since that will always result in a large drop in mrr, skewing results). I found that 70 percent of the organizations that churned had zero or less than zero mrr growth in the last 6 months of being with us. It would seem like stagnation in mrr is an early warning sign for churn.


```WITH most_recent_months AS (
    SELECT
        organization_id,
        SUM(mom_total_mrr_delta) AS total_mrr_delta
    FROM "postgres"."bloom"."monthly_organization_activity" moa
    WHERE organization_is_churned AND NOT organization_is_churned_in_month
    AND month >= DATE_TRUNC('month', organization_churned_at) - INTERVAL '6 months'
    GROUP BY 1
)
SELECT
    COUNT(CASE WHEN total_mrr_delta <= 0 THEN organization_id END)*1.0 / COUNT(organization_id) AS zero_growth_organization_percentage
FROM most_recent_months
```

## Which customer segments are most valuable?

I found that this question was best answer by taking the sum of total revenue accross all of our organizational segments. That would include business os type, current plan, industry, and size. After getting this raw number, I used a windowed function to get the #1 segment out of each of these categorys. I found that EOS is our most valuable OS, enterprise is our most valuable plan, tech is our most valuable industry, and small organizations (1-10 employees) are our most valuable organizations.

```WITH business_os_type AS (
    SELECT
        organization_business_os_type,
        SUM(total_revenue) AS total_revenue
    FROM "postgres"."bloom"."organization_segments"
    GROUP BY 1
),
industry AS (
    SELECT
        organization_industry,
        SUM(total_revenue) AS total_revenue
    FROM "postgres"."bloom"."organization_segments"
    GROUP BY 1
),
size_cohort AS (
    SELECT
        organization_size_cohort,
        SUM(total_revenue) AS total_revenue
    FROM "postgres"."bloom"."organization_segments"
    GROUP BY 1
),
plan_name_current AS (
     SELECT
        organization_plan_name_current,
        SUM(total_revenue) AS total_revenue
    FROM "postgres"."bloom"."organization_segments"
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
```

## How do different Business OS types perform?

To answer this question I wanted to get some aggregate usage and financial numbers, based on organizational segments. I'm looking at both the raw values (revenue, users, etc.) AS well has per user/event metrics. In a raw numbers sense EOS is our highest grossing OS but custom OS gives us more bang for our buck on a per-user basis. That being said a custom OS may cost more money to build/implement so that analysis would need to be done in order to say for sure. We also get the most per user usage out of custom OS's and the least amount of issues. To me this would lead my to believe a custom OS would out perform all others.

```SELECT
    organization_business_os_type,
    SUM(total_revenue) AS total_revenue,
    SUM(total_users) AS total_users,
    SUM(total_events) AS total_events,
    SUM(total_issues) AS total_issues,
    SUM(total_revenue) / SUM(total_users) AS revenue_per_user,
    SUM(total_revenue) / SUM(total_events) AS revenue_per_event,
    SUM(total_events) / SUM(total_users) AS events_per_user,
    SUM(total_issues) / SUM(total_users) AS issues_per_user
FROM "postgres"."bloom"."organization_segments"
GROUP BY 1
```

## What engagement patterns, if any, are associated with plan upgrades?

To determine engagment patterns associated with plan upgrades, I decided to use a similar approach to the one I used to determine early warning signs of churn risk. I decided to look back 3 months from the date the account was upgraded and compare usage numbers. It seems like average usage doubles in the 3 months leading up to an upgrade vs. the baseline (4.4 events to 8.6 events). We can say that large spikes in usage is a good indicator that a customer is ready to upgrade.

```WITH months AS(
    SELECT
        organization_id,
        month,
        subscription_change_reason,
        num_events,
        num_rocks,
        num_issues,
        num_meetings,
        num_scorecards,
        num_todos,
        num_headlines,
        MAX(CASE WHEN subscription_change_reason = 'UPGRADE' THEN 1 ELSE 0 END)
            OVER(
                PARTITION BY organization_id
                ORDER BY month
                ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING
            ) AS is_within_3_months_of_upgrade
    FROM "postgres"."bloom"."monthly_organization_activity"
    WHERE NOT organization_is_churned_in_month
),
groupings AS (
    SELECT
        organization_id,
        month,
        subscription_change_reason,
        num_events,
        num_rocks,
        num_issues,
        num_meetings,
        num_scorecards,
        num_todos,
        num_headlines,
        is_within_3_months_of_upgrade,
        CASE
            WHEN subscription_change_reason = 'UPGRADE' THEN 'UPGRADE MONTH'
            WHEN is_within_3_months_of_upgrade = 1 THEN 'PRE UPGRADE 3 MONTHS'
            ELSE 'BASELINE'
        END AS period
    FROM months
)
SELECT
    period,
    COUNT(*) AS num_months,
    AVG(num_events) AS avg_total_events,
    AVG(num_rocks) AS avg_rocks,
    AVG(num_issues) AS avg_issues,
    AVG(num_meetings) AS avg_meetings,
    AVG(num_scorecards) AS avg_scorecards,
    AVG(num_todos) AS avg_todos,
    AVG(num_headlines) AS avg_headlines 
FROM groupings
GROUP BY 1
```