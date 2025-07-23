# Monthly KPI Analysis - dbt Project

This dbt project analyzes key monthly KPIs for the `thelook_ecommerce` dataset on BigQuery.  
It focuses on user behavior, sales performance, and product lifecycle metrics.

---

## KPIs Included
The project computes the following metrics on a **monthly level**:

- New registered users
- New purchasing users
- Total registered & purchasing users (cumulative)
- Order volume
- Total revenue and profit
- Churned users (users inactive for over 12 months)
- Returned and canceled orders & users
- Return and cancellation rates

---

## dbt Models Breakdown

| Model Name                | Description                                                                 |
|--------------------------|-----------------------------------------------------------------------------|
| `user_first_signup`      | Extracts the month/year of each user's first registration                  |
| `user_first_purchase`    | Identifies the first successful purchase month for each user               |
| `new_users_by_m`         | Aggregates count of new registered users by month                          |
| `new_purchasing_by_m`    | Aggregates new purchasers by month                                         |
| `sales_by_m`             | Counts non-canceled, non-returned orders per month                         |
| `revenue_by_m`           | Calculates total revenue and profit from order items                       |
| `returned_by_m`          | Counts monthly returned orders and affected users                          |
| `canceled_by_m`          | Same as above, for canceled orders                                          |
| `churn_by_m`             | Identifies users who churned (12+ months without a valid purchase)         |
| `monthly_kpi_rollup`     | Final model aggregating all metrics into a single monthly snapshot         |

---

## How to Run

1. Set up your BigQuery profile in `profiles.yml`
2. Run the models using:
```bash
dbt run
