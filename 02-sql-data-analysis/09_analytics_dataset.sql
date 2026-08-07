-- ============================================================
-- FRAUD DETECTION & TRANSACTION RISK ANALYTICS
-- 09 - ANALYTICS DATASET
-- ============================================================

USE adventureworks2017;

-- 1. Final analytics dataset for Python and Tableau

CREATE OR REPLACE VIEW vw_fraud_analytics_dataset AS

SELECT
    SalesOrderID,
    CustomerID,
    OrderDate,

    YEAR(OrderDate) AS order_year,
    MONTH(OrderDate) AS order_month,
    DATE_FORMAT(OrderDate, '%Y-%m') AS order_year_month,

    order_value,
    OnlineOrderFlag,
    CreditCardID,

    previous_order_date,
    days_since_previous_order,
    prior_order_count,
    prior_avg_order_value,
    amount_vs_customer_avg,

    billing_city,
    billing_state,
    shipping_city,
    shipping_state,

    same_day_repeat_flag,
    rapid_repeat_flag,
    amount_spike_flag,
    city_mismatch_flag,
    state_mismatch_flag,

    CASE
        WHEN same_day_repeat_flag = 1
          OR rapid_repeat_flag = 1
        THEN 1
        ELSE 0
    END AS velocity_risk_flag,

    CASE
        WHEN city_mismatch_flag = 1
          OR state_mismatch_flag = 1
        THEN 1
        ELSE 0
    END AS geographic_mismatch_flag,

    same_day_repeat_flag
    + rapid_repeat_flag
    + amount_spike_flag
    + CASE
        WHEN city_mismatch_flag = 1
          OR state_mismatch_flag = 1
        THEN 1
        ELSE 0
      END AS risk_flag_count,

    velocity_risk_points,
    behavioural_risk_points,
    geographic_risk_points,

    transaction_risk_score,
    risk_dimension_count,
    risk_level,
    risk_reason,

    CASE
        WHEN risk_level = 'High' THEN 1
        ELSE 0
    END AS high_risk_flag,

    CASE
        WHEN risk_level IN ('High', 'Medium') THEN 1
        ELSE 0
    END AS flagged_transaction_flag,

    CASE
        WHEN risk_level = 'High' THEN 3
        WHEN risk_level = 'Medium' THEN 2
        ELSE 1
    END AS risk_level_order

FROM vw_transaction_risk_analysis;



-- Validate total transaction count

SELECT
    COUNT(*) AS total_transactions
FROM vw_fraud_analytics_dataset;


-- Validate risk-level distribution

SELECT
    risk_level,
    COUNT(*) AS transaction_count
FROM vw_fraud_analytics_dataset
GROUP BY
    risk_level,
    risk_level_order
ORDER BY
    risk_level_order DESC;


-- 2. Preview highest-priority transactions

SELECT
    SalesOrderID,
    CustomerID,
    OrderDate,
    order_year,
    order_month,
    order_year_month,

    order_value,

    days_since_previous_order,
    prior_order_count,
    prior_avg_order_value,
    amount_vs_customer_avg,

    velocity_risk_flag,
    geographic_mismatch_flag,
    risk_flag_count,

    transaction_risk_score,
    risk_dimension_count,
    risk_level,
    risk_reason

FROM vw_fraud_analytics_dataset

WHERE flagged_transaction_flag = 1

ORDER BY
    transaction_risk_score DESC,
    risk_dimension_count DESC,
    amount_vs_customer_avg DESC,
    order_value DESC

LIMIT 100;


-- Validate flagged transaction volume

SELECT
    COUNT(*) AS flagged_transactions,

    SUM(
        CASE
            WHEN risk_level = 'High' THEN 1
            ELSE 0
        END
    ) AS high_risk_transactions,

    SUM(
        CASE
            WHEN risk_level = 'Medium' THEN 1
            ELSE 0
        END
    ) AS medium_risk_transactions

FROM vw_fraud_analytics_dataset

WHERE flagged_transaction_flag = 1;


-- 3. Monthly risk summary

SELECT
    order_year_month,

    COUNT(*) AS total_transactions,

    SUM(flagged_transaction_flag) AS flagged_transactions,

    SUM(high_risk_flag) AS high_risk_transactions,

    ROUND(
        SUM(flagged_transaction_flag) * 100.0 / COUNT(*),
        2
    ) AS flagged_transaction_rate

FROM vw_fraud_analytics_dataset

GROUP BY order_year_month

ORDER BY order_year_month;