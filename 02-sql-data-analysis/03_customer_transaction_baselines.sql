-- ============================================================
-- FRAUD DETECTION & TRANSACTION RISK ANALYTICS
-- 03 - CUSTOMER TRANSACTION BASELINES
-- ============================================================

USE adventureworks2017;

-- 1. Customer transaction sequence

SELECT
    SalesOrderID,
    CustomerID,
    OrderDate,
    ROUND(TotalDue, 2) AS order_value,

    ROW_NUMBER() OVER (
        PARTITION BY CustomerID
        ORDER BY OrderDate, SalesOrderID
    ) AS customer_order_number,

    COUNT(*) OVER (
        PARTITION BY CustomerID
    ) AS customer_total_orders

FROM salesorderheader
ORDER BY
    CustomerID,
    OrderDate,
    SalesOrderID;


-- 2. Previous customer transaction

WITH order_sequence AS (
    SELECT
        SalesOrderID,
        CustomerID,
        OrderDate,
        TotalDue,

        LAG(OrderDate) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate, SalesOrderID
        ) AS previous_order_date,

        LAG(TotalDue) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate, SalesOrderID
        ) AS previous_order_value

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

    ROUND(TotalDue, 2) AS order_value,
    ROUND(previous_order_value, 2) AS previous_order_value,

    ROUND(
        TotalDue / NULLIF(previous_order_value, 0),
        2
    ) AS value_vs_previous_order

FROM order_sequence
ORDER BY
    CustomerID,
    OrderDate,
    SalesOrderID;


-- 3. Historical customer spending baseline

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
        ) AS prior_avg_order_value,

        MAX(TotalDue) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate, SalesOrderID
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_max_order_value

    FROM salesorderheader
)

SELECT
    SalesOrderID,
    CustomerID,
    OrderDate,
    ROUND(TotalDue, 2) AS order_value,
    prior_order_count,
    ROUND(prior_avg_order_value, 2) AS prior_avg_order_value,
    ROUND(prior_max_order_value, 2) AS prior_max_order_value,

    ROUND(
        TotalDue - prior_avg_order_value,
        2
    ) AS amount_above_customer_avg,

    ROUND(
        TotalDue / NULLIF(prior_avg_order_value, 0),
        2
    ) AS amount_vs_customer_avg

FROM historical_baseline
ORDER BY
    CustomerID,
    OrderDate,
    SalesOrderID;


-- 4. Largest deviations from customer history

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

ORDER BY amount_vs_customer_avg DESC

LIMIT 100;