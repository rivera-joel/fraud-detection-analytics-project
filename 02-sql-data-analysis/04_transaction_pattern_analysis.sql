-- ============================================================
-- FRAUD DETECTION & TRANSACTION RISK ANALYTICS
-- 04 - TRANSACTION PATTERN ANALYSIS
-- ============================================================

USE adventureworks2017;


-- 1. Customer transaction timing

WITH transaction_sequence AS (
    SELECT
        SalesOrderID,
        CustomerID,
        OrderDate,
        TotalDue,

        LAG(OrderDate) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate, SalesOrderID
        ) AS previous_order_date

    FROM salesorderheader
)

SELECT
    SalesOrderID,
    CustomerID,
    OrderDate,
    previous_order_date,

    DATEDIFF(
        OrderDate,
        previous_order_date
    ) AS days_since_previous_order,

    ROUND(TotalDue, 2) AS order_value

FROM transaction_sequence
ORDER BY
    CustomerID,
    OrderDate,
    SalesOrderID;


-- 2. Inter-order gap distribution

WITH transaction_sequence AS (
    SELECT
        SalesOrderID,
        CustomerID,
        OrderDate,

        LAG(OrderDate) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate, SalesOrderID
        ) AS previous_order_date

    FROM salesorderheader
),

order_gaps AS (
    SELECT
        SalesOrderID,
        CustomerID,
        OrderDate,

        DATEDIFF(
            OrderDate,
            previous_order_date
        ) AS days_since_previous_order

    FROM transaction_sequence
)

SELECT
    CASE
        WHEN days_since_previous_order IS NULL THEN 'First order'
        WHEN days_since_previous_order = 0 THEN 'Same day'
        WHEN days_since_previous_order BETWEEN 1 AND 7 THEN '1-7 days'
        WHEN days_since_previous_order BETWEEN 8 AND 30 THEN '8-30 days'
        WHEN days_since_previous_order BETWEEN 31 AND 90 THEN '31-90 days'
        ELSE 'More than 90 days'
    END AS order_gap_segment,

    COUNT(*) AS transaction_count

FROM order_gaps
GROUP BY order_gap_segment
ORDER BY transaction_count DESC;


-- 3. Rapid repeat transactions

WITH transaction_sequence AS (
    SELECT
        SalesOrderID,
        CustomerID,
        OrderDate,
        TotalDue,

        LAG(OrderDate) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate, SalesOrderID
        ) AS previous_order_date

    FROM salesorderheader
)

SELECT
    SalesOrderID,
    CustomerID,
    OrderDate,
    previous_order_date,

    DATEDIFF(
        OrderDate,
        previous_order_date
    ) AS days_since_previous_order,

    ROUND(TotalDue, 2) AS order_value

FROM transaction_sequence
WHERE previous_order_date IS NOT NULL
  AND DATEDIFF(OrderDate, previous_order_date) <= 7
ORDER BY
    days_since_previous_order,
    CustomerID,
    OrderDate,
    SalesOrderID;


-- 4. High-value deviations from customer history

WITH historical_baseline AS (
    SELECT
        SalesOrderID,
        CustomerID,
        OrderDate,
        TotalDue,

        COUNT(*) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate, SalesOrderID
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_order_count,

        AVG(TotalDue) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate, SalesOrderID
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_avg_order_value

    FROM salesorderheader
)

SELECT
    SalesOrderID,
    CustomerID,
    OrderDate,
    ROUND(TotalDue, 2) AS order_value,
    prior_order_count,
    ROUND(prior_avg_order_value, 2) AS prior_avg_order_value,

    ROUND(
        TotalDue / NULLIF(prior_avg_order_value, 0),
        2
    ) AS amount_vs_customer_avg

FROM historical_baseline
WHERE prior_order_count >= 2
  AND TotalDue / NULLIF(prior_avg_order_value, 0) >= 3
ORDER BY amount_vs_customer_avg DESC;


-- 5. Combined transaction pattern indicators

WITH transaction_history AS (
    SELECT
        SalesOrderID,
        CustomerID,
        OrderDate,
        TotalDue,
        OnlineOrderFlag,
        CreditCardID,

        LAG(OrderDate) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate, SalesOrderID
        ) AS previous_order_date,

        COUNT(*) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate, SalesOrderID
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_order_count,

        AVG(TotalDue) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate, SalesOrderID
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_avg_order_value

    FROM salesorderheader
),

pattern_features AS (
    SELECT
        SalesOrderID,
        CustomerID,
        OrderDate,
        TotalDue,
        OnlineOrderFlag,
        CreditCardID,
        previous_order_date,
        prior_order_count,
        prior_avg_order_value,

        DATEDIFF(
            OrderDate,
            previous_order_date
        ) AS days_since_previous_order,

        TotalDue / NULLIF(
            prior_avg_order_value,
            0
        ) AS amount_vs_customer_avg

    FROM transaction_history
)

SELECT
    SalesOrderID,
    CustomerID,
    OrderDate,
    ROUND(TotalDue, 2) AS order_value,
    OnlineOrderFlag,
    CreditCardID,
    days_since_previous_order,
    prior_order_count,
    ROUND(prior_avg_order_value, 2) AS prior_avg_order_value,
    ROUND(amount_vs_customer_avg, 2) AS amount_vs_customer_avg,

    CASE
        WHEN days_since_previous_order = 0 THEN 1
        ELSE 0
    END AS same_day_repeat_flag,

    CASE
        WHEN days_since_previous_order BETWEEN 0 AND 7 THEN 1
        ELSE 0
    END AS rapid_repeat_flag,

    CASE
        WHEN prior_order_count >= 2
         AND amount_vs_customer_avg >= 3 THEN 1
        ELSE 0
    END AS amount_spike_flag

FROM pattern_features
WHERE days_since_previous_order BETWEEN 0 AND 7
   OR (
        prior_order_count >= 2
        AND amount_vs_customer_avg >= 3
   )
ORDER BY
    amount_spike_flag DESC,
    same_day_repeat_flag DESC,
    rapid_repeat_flag DESC,
    amount_vs_customer_avg DESC;