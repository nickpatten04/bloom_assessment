# Analytics Engineer - Take-Home Assessment

## Scenario

You are joining the data team at a SaaS company that sells a "Business Operating System" platform. The product supports multiple operating system frameworks (EOS, Pinnacle, Scaling Up, and Custom) — think of these as product editions that different customer segments adopt. Leadership wants visibility into revenue health and expansion opportunities.

Using the provided sample data, investigate the following questions:

- How do activity levels correlate with MRR (Monthly Recurring Revenue) changes?
- What early warning signs indicate churn risk?
- Which customer segments are most valuable?
- How do different Business OS types perform?
- What engagement patterns, if any, are associated with plan upgrades?

## What we expect

Build a **dbt project** using [dbt-core](https://docs.getdbt.com/docs/core/installation-overview) that models this data and answers the questions above. Use the CSV files in `seeds/` as [dbt seeds](https://docs.getdbt.com/docs/build/seeds). You can use any database adapter you prefer (DuckDB is the easiest to set up locally via `dbt-duckdb`).

### Deliverables

1. **Data models** — staging, intermediate, and/or mart layers that structure the raw data for analysis. The source data has quality issues — show us how you handle cleanup in your layer of preference.
2. **Metrics and calculations** — define key metrics (MRR, churn rate, engagement scores, etc.) and how you calculate them. You decide where and how to define them — in SQL models, YAML, documentation, or however you think is best.
3. **Findings** — write a `FINDINGS.md` in your repo answering the investigation questions above. Include the key numbers and patterns you discovered, referencing the models or queries that support them. You can also build PDFs, a small presentation, or whatever method you prefer to communicate your findings.

Push your dbt project to a GitHub repository and share the link.

### Guidelines

- Estimated time: **2-3 hours**
- Deadline: **3 business days** from receipt
- Focus on clarity and correctness over polish
- Don't worry about completing everything perfectly. Anything you don't finish or questions you're unsure about can be points of discussion during the technical interview
- `mrr_amount` is pre-calculated as `base_price + (seats × per_seat_price)` for active subscriptions. Churn records have `mrr_amount = 0` (revenue stops at churn).
- `mrr_amount` is always a monthly figure, regardless of `billing_interval`
- Perfectly OK to use AI. If you end up using an AI then share a copy of the conversation with the AI. A human will review the work done + steps taken with the AI.

## Data

All files are in `seeds/` and should be loaded via `dbt seed`. The data comes from a production export and may contain quality issues typical of real-world source data.

| File | Rows | Description |
|---|---|---|
| `organizations.csv` | ~200 | Customer organizations with Business OS type, industry, size, and status |
| `plans.csv` | 4 | Pricing plans with base + per-seat pricing |
| `subscriptions.csv` | ~330 | Subscription history including upgrades, downgrades, churn, and reactivations |
| `users.csv` | ~2,000 | Users across organizations with roles and registration status |
| `activity_events.csv` | ~17,000 | Product usage events across 6 feature categories |

### Schema reference

**organizations**: `organization_id`, `organization_name`, `business_os_type` (EOS / Pinnacle / Scaling Up / Custom), `industry`, `employee_count`, `status` (active / churned / trial), `created_at`, `churned_at`

**plans**: `plan_id`, `plan_name` (Free / Starter / Professional / Enterprise), `base_price`, `per_seat_price`

**subscriptions**: `subscription_id`, `organization_id`, `plan_id`, `seats`, `mrr_amount`, `billing_interval` (monthly / annual), `started_at`, `ended_at`, `change_reason` (new / upgrade / downgrade / churn / reactivation). Each row represents a subscription period — an organization may have multiple rows showing its plan history over time.

**users**: `user_id`, `organization_id`, `user_name`, `role` (owner / admin / manager / member), `is_registered`, `created_at`, `last_active_at`

**activity_events**: `event_id`, `organization_id`, `user_id`, `feature_category` (meetings / scorecards / rocks / todos / issues / headlines), `event_type`, `event_date`, `event_timestamp`
