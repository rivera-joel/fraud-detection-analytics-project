-- ============================================================
-- FRAUD DETECTION & TRANSACTION RISK ANALYTICS 
-- 06 - FRAUD RISK FEATURES
-- ============================================================

USE adventureworks2017;


-- 1. Build transaction-level behavioural and geographic features

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
        ) AS prior_avg_order_value,

        MAX(soh.TotalDue) OVER (
            PARTITION BY soh.CustomerID
            ORDER BY soh.OrderDate, soh.SalesOrderID
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_max_order_value

    FROM salesorderheader AS soh
),

behavioural_features AS (
    SELECT
        SalesOrderID,
        CustomerID,
        OrderDate,
        TotalDue,
        OnlineOrderFlag,
        CreditCardID,
        BillToAddressID,
        ShipToAddressID,
        previous_order_date,
        prior_order_count,
        prior_avg_order_value,
        prior_max_order_value,

        DATEDIFF(
            OrderDate,
            previous_order_date
        ) AS days_since_previous_order,

        TotalDue / NULLIF(
            prior_avg_order_value,
            0
        ) AS amount_vs_customer_avg

    FROM transaction_history
),

geographic_features AS (
    SELECT
        bf.*,

        bill.City AS billing_city,
        bill.StateProvinceID AS billing_state,

        ship.City AS shipping_city,
        ship.StateProvinceID AS shipping_state,

        CASE
            WHEN bill.City <> ship.City THEN 1
            ELSE 0
        END AS billing_shipping_city_mismatch_flag,

        CASE
            WHEN bill.StateProvinceID <> ship.StateProvinceID THEN 1
            ELSE 0
        END AS billing_shipping_state_mismatch_flag

    FROM behavioural_features AS bf

    LEFT JOIN address AS bill
        ON bf.BillToAddressID = bill.AddressID

    LEFT JOIN address AS ship
        ON bf.ShipToAddressID = ship.AddressID
),

risk_features AS (
    SELECT
        SalesOrderID,
        CustomerID,
        OrderDate,
        TotalDue,
        OnlineOrderFlag,
        CreditCardID,

        previous_order_date,
        days_since_previous_order,
        prior_order_count,
        prior_avg_order_value,
        prior_max_order_value,
        amount_vs_customer_avg,

        billing_city,
        billing_state,
        shipping_city,
        shipping_state,

        billing_shipping_city_mismatch_flag,
        billing_shipping_state_mismatch_flag,

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

    FROM geographic_features
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
        prior_max_order_value,
        2
    ) AS prior_max_order_value,

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
    billing_shipping_city_mismatch_flag,
    billing_shipping_state_mismatch_flag

FROM risk_features

ORDER BY
    CustomerID,
    OrderDate,
    SalesOrderID;
    
    
    
-- 2. Risk feature distribution

WITH transaction_history AS (
    SELECT
        soh.SalesOrderID,
        soh.CustomerID,
        soh.OrderDate,
        soh.TotalDue,
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

feature_summary AS (
    SELECT
        th.SalesOrderID,

        CASE
            WHEN DATEDIFF(
                th.OrderDate,
                th.previous_order_date
            ) = 0 THEN 1
            ELSE 0
        END AS same_day_repeat_flag,

        CASE
            WHEN DATEDIFF(
                th.OrderDate,
                th.previous_order_date
            ) BETWEEN 1 AND 7 THEN 1
            ELSE 0
        END AS rapid_repeat_flag,

        CASE
            WHEN th.prior_order_count >= 2
             AND th.TotalDue / NULLIF(
                    th.prior_avg_order_value,
                    0
                 ) >= 3
                THEN 1
            ELSE 0
        END AS amount_spike_flag,

        CASE
            WHEN bill.City <> ship.City THEN 1
            ELSE 0
        END AS city_mismatch_flag,

        CASE
            WHEN bill.StateProvinceID <> ship.StateProvinceID THEN 1
            ELSE 0
        END AS state_mismatch_flag

    FROM transaction_history AS th

    LEFT JOIN address AS bill
        ON th.BillToAddressID = bill.AddressID

    LEFT JOIN address AS ship
        ON th.ShipToAddressID = ship.AddressID
)

SELECT
    COUNT(*) AS total_transactions,

    SUM(same_day_repeat_flag) AS same_day_repeat_count,
    SUM(rapid_repeat_flag) AS rapid_repeat_count,
    SUM(amount_spike_flag) AS amount_spike_count,
    SUM(city_mismatch_flag) AS city_mismatch_count,
    SUM(state_mismatch_flag) AS state_mismatch_count,

    SUM(
        CASE
            WHEN (
                same_day_repeat_flag
                + rapid_repeat_flag
                + amount_spike_flag
                + city_mismatch_flag
                + state_mismatch_flag
            ) >= 2 THEN 1
            ELSE 0
        END
    ) AS transactions_with_multiple_signals

FROM feature_summary;


-- 3. Transactions with multiple risk signals

WITH transaction_history AS (
    SELECT
        soh.SalesOrderID,
        soh.CustomerID,
        soh.OrderDate,
        soh.TotalDue,
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

feature_summary AS (
    SELECT
        th.SalesOrderID,
        th.CustomerID,
        th.OrderDate,
        th.TotalDue,

        DATEDIFF(
            th.OrderDate,
            th.previous_order_date
        ) AS days_since_previous_order,

        ROUND(
            th.TotalDue / NULLIF(
                th.prior_avg_order_value,
                0
            ),
            2
        ) AS amount_vs_customer_avg,

        CASE
            WHEN DATEDIFF(
                th.OrderDate,
                th.previous_order_date
            ) = 0 THEN 1
            ELSE 0
        END AS same_day_repeat_flag,

        CASE
            WHEN DATEDIFF(
                th.OrderDate,
                th.previous_order_date
            ) BETWEEN 1 AND 7 THEN 1
            ELSE 0
        END AS rapid_repeat_flag,

        CASE
            WHEN th.prior_order_count >= 2
             AND th.TotalDue / NULLIF(
                    th.prior_avg_order_value,
                    0
                 ) >= 3
                THEN 1
            ELSE 0
        END AS amount_spike_flag,

        CASE
            WHEN bill.City <> ship.City THEN 1
            ELSE 0
        END AS city_mismatch_flag,

        CASE
            WHEN bill.StateProvinceID <> ship.StateProvinceID THEN 1
            ELSE 0
        END AS state_mismatch_flag

    FROM transaction_history AS th

    LEFT JOIN address AS bill
        ON th.BillToAddressID = bill.AddressID

    LEFT JOIN address AS ship
        ON th.ShipToAddressID = ship.AddressID
)

SELECT
    SalesOrderID,
    CustomerID,
    OrderDate,
    ROUND(TotalDue, 2) AS order_value,
    days_since_previous_order,
    amount_vs_customer_avg,

    same_day_repeat_flag,
    rapid_repeat_flag,
    amount_spike_flag,
    city_mismatch_flag,
    state_mismatch_flag,

    (
        same_day_repeat_flag
        + rapid_repeat_flag
        + amount_spike_flag
        + city_mismatch_flag
        + state_mismatch_flag
    ) AS signal_count

FROM feature_summary

WHERE (
    same_day_repeat_flag
    + rapid_repeat_flag
    + amount_spike_flag
    + city_mismatch_flag
    + state_mismatch_flag
) >= 2

ORDER BY
    signal_count DESC,
    amount_vs_customer_avg DESC,
    order_value DESC;
