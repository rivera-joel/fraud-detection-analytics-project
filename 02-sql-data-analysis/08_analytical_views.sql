-- ============================================================
-- FRAUD DETECTION & TRANSACTION RISK ANALYTICS
-- 08 - ANALYTICAL VIEWS
-- ============================================================

USE adventureworks2017;


-- 1. Transaction risk analytical view

CREATE OR REPLACE VIEW vw_transaction_risk_analysis AS

WITH transaction_history AS (
    SELECT
        soh.SalesOrderID,
        soh.CustomerID,
        soh.OrderDate,
        soh.TotalDue,
        soh.OnlineOrderFlag,
        soh.CreditCardID,
        soh.BillToAddressID,
        soh.ShipToAddressID,

        LAG(soh.OrderDate) OVER (
            PARTITION BY soh.CustomerID
            ORDER BY soh.OrderDate, soh.SalesOrderID
        ) AS previous_order_date,

        COUNT(*) OVER (
            PARTITION BY soh.CustomerID
            ORDER BY soh.OrderDate, soh.SalesOrderID
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_order_count,

        AVG(soh.TotalDue) OVER (
            PARTITION BY soh.CustomerID
            ORDER BY soh.OrderDate, soh.SalesOrderID
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_avg_order_value

    FROM salesorderheader AS soh
),

transaction_features AS (
    SELECT
        th.*,

        DATEDIFF(
            th.OrderDate,
            th.previous_order_date
        ) AS days_since_previous_order,

        th.TotalDue / NULLIF(
            th.prior_avg_order_value,
            0
        ) AS amount_vs_customer_avg,

        bill.City AS billing_city,
        bill.StateProvinceID AS billing_state,

        ship.City AS shipping_city,
        ship.StateProvinceID AS shipping_state

    FROM transaction_history AS th

    LEFT JOIN address AS bill
        ON th.BillToAddressID = bill.AddressID

    LEFT JOIN address AS ship
        ON th.ShipToAddressID = ship.AddressID
),

risk_flags AS (
    SELECT
        *,

        CASE
            WHEN days_since_previous_order = 0 THEN 1
            ELSE 0
        END AS same_day_repeat_flag,

        CASE
            WHEN days_since_previous_order BETWEEN 1 AND 7 THEN 1
            ELSE 0
        END AS rapid_repeat_flag,

        CASE
            WHEN prior_order_count >= 2
             AND amount_vs_customer_avg >= 3 THEN 1
            ELSE 0
        END AS amount_spike_flag,

        CASE
            WHEN billing_city <> shipping_city THEN 1
            ELSE 0
        END AS city_mismatch_flag,

        CASE
            WHEN billing_state <> shipping_state THEN 1
            ELSE 0
        END AS state_mismatch_flag

    FROM transaction_features
),

risk_components AS (
    SELECT
        *,

        CASE
            WHEN same_day_repeat_flag = 1 THEN 2
            WHEN rapid_repeat_flag = 1 THEN 1
            ELSE 0
        END AS velocity_risk_points,

        CASE
            WHEN amount_spike_flag = 1 THEN 3
            ELSE 0
        END AS behavioural_risk_points,

        CASE
            WHEN state_mismatch_flag = 1 THEN 2
            WHEN city_mismatch_flag = 1 THEN 1
            ELSE 0
        END AS geographic_risk_points

    FROM risk_flags
),

risk_scores AS (
    SELECT
        *,

        velocity_risk_points
        + behavioural_risk_points
        + geographic_risk_points
            AS transaction_risk_score,

        CASE
            WHEN same_day_repeat_flag = 1
              OR rapid_repeat_flag = 1
                THEN 1
            ELSE 0
        END
        +
        amount_spike_flag
        +
        CASE
            WHEN city_mismatch_flag = 1
              OR state_mismatch_flag = 1
                THEN 1
            ELSE 0
        END AS risk_dimension_count

    FROM risk_components
)

SELECT
    SalesOrderID,
    CustomerID,
    OrderDate,

    ROUND(TotalDue, 2) AS order_value,

    OnlineOrderFlag,
    CreditCardID,

    previous_order_date,
    days_since_previous_order,
    prior_order_count,

    ROUND(
        prior_avg_order_value,
        2
    ) AS prior_avg_order_value,

    ROUND(
        amount_vs_customer_avg,
        2
    ) AS amount_vs_customer_avg,

    billing_city,
    billing_state,
    shipping_city,
    shipping_state,

    same_day_repeat_flag,
    rapid_repeat_flag,
    amount_spike_flag,
    city_mismatch_flag,
    state_mismatch_flag,

    velocity_risk_points,
    behavioural_risk_points,
    geographic_risk_points,

    transaction_risk_score,
    risk_dimension_count,

    CASE
        WHEN transaction_risk_score >= 4 THEN 'High'
        WHEN transaction_risk_score BETWEEN 1 AND 3 THEN 'Medium'
        ELSE 'Low'
    END AS risk_level,

    COALESCE(
        NULLIF(
            CONCAT_WS(
                ', ',

                CASE
                    WHEN same_day_repeat_flag = 1
                        THEN 'Same-day repeat'
                END,

                CASE
                    WHEN rapid_repeat_flag = 1
                        THEN 'Rapid repeat (1-7 days)'
                END,

                CASE
                    WHEN amount_spike_flag = 1
                        THEN 'Amount spike'
                END,

                CASE
                    WHEN state_mismatch_flag = 1
                        THEN 'State/province mismatch'

                    WHEN city_mismatch_flag = 1
                        THEN 'City mismatch'
                END
            ),
            ''
        ),
        'No risk indicators'
    ) AS risk_reason

FROM risk_scores;



SELECT *
FROM vw_transaction_risk_analysis
ORDER BY
    transaction_risk_score DESC,
    amount_vs_customer_avg DESC
LIMIT 100;

SELECT COUNT(*)
FROM vw_transaction_risk_analysis;

-- ============================================================
-- 2. High-risk transaction view
-- ============================================================

CREATE OR REPLACE VIEW vw_high_risk_transactions AS

SELECT
    SalesOrderID,
    CustomerID,
    OrderDate,
    order_value,
    OnlineOrderFlag,
    CreditCardID,

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

    transaction_risk_score,
    risk_dimension_count,
    risk_level,
    risk_reason

FROM vw_transaction_risk_analysis

WHERE risk_level = 'High';

SELECT *
FROM vw_high_risk_transactions
ORDER BY transaction_risk_score DESC;

-- ============================================================
-- 3. Risk-level summary view
-- ============================================================

CREATE OR REPLACE VIEW vw_risk_level_summary AS

SELECT
    risk_level,

    COUNT(*) AS transaction_count,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_transactions,

    ROUND(
        SUM(order_value),
        2
    ) AS total_order_value,

    ROUND(
        AVG(order_value),
        2
    ) AS avg_order_value,

    ROUND(
        MAX(order_value),
        2
    ) AS max_order_value

FROM vw_transaction_risk_analysis

GROUP BY risk_level;

SELECT *
FROM vw_risk_level_summary;

-- ============================================================
-- 4. Customer risk summary view
-- ============================================================

CREATE OR REPLACE VIEW vw_customer_risk_summary AS

SELECT
    CustomerID,

    COUNT(*) AS total_transactions,

    ROUND(
        SUM(order_value),
        2
    ) AS total_order_value,

    ROUND(
        AVG(order_value),
        2
    ) AS avg_order_value,

    MAX(transaction_risk_score) AS max_transaction_risk_score,

    ROUND(
        AVG(transaction_risk_score),
        2
    ) AS avg_transaction_risk_score,

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
    ) AS medium_risk_transactions,

    SUM(
        same_day_repeat_flag
    ) AS same_day_repeat_count,

    SUM(
        rapid_repeat_flag
    ) AS rapid_repeat_count,

    SUM(
        amount_spike_flag
    ) AS amount_spike_count,

    SUM(
        city_mismatch_flag
    ) AS city_mismatch_count,

    SUM(
        state_mismatch_flag
    ) AS state_mismatch_count

FROM vw_transaction_risk_analysis

GROUP BY CustomerID;

SELECT *
FROM vw_customer_risk_summary
ORDER BY
    high_risk_transactions DESC,
    max_transaction_risk_score DESC,
    medium_risk_transactions DESC
LIMIT 100;
