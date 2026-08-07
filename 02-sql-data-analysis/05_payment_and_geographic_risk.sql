-- ============================================================
-- FRAUD DETECTION & TRANSACTION RISK ANALYTICS
-- 05 - PAYMENT & GEOGRAPHIC RISK
-- ============================================================

USE adventureworks2017;


-- 1. Billing and shipping location distribution

SELECT
    CASE
        WHEN bill.StateProvinceID = ship.StateProvinceID
            THEN 'Same state/province'
        ELSE 'Different state/province'
    END AS location_relationship,

    COUNT(*) AS transaction_count

FROM salesorderheader AS soh

LEFT JOIN address AS bill
    ON soh.BillToAddressID = bill.AddressID

LEFT JOIN address AS ship
    ON soh.ShipToAddressID = ship.AddressID

GROUP BY location_relationship
ORDER BY transaction_count DESC;


-- 2. Billing and shipping location mismatches

SELECT
    soh.SalesOrderID,
    soh.CustomerID,
    soh.OrderDate,
    ROUND(soh.TotalDue, 2) AS order_value,

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

FROM salesorderheader AS soh

LEFT JOIN address AS bill
    ON soh.BillToAddressID = bill.AddressID

LEFT JOIN address AS ship
    ON soh.ShipToAddressID = ship.AddressID

WHERE bill.City <> ship.City
   OR bill.StateProvinceID <> ship.StateProvinceID

ORDER BY
    billing_shipping_state_mismatch_flag DESC,
    order_value DESC;


-- 3. Payment-card ownership verification

WITH payment_verification AS (
    SELECT
        soh.SalesOrderID,
        soh.CustomerID,
        soh.CreditCardID,
        soh.OnlineOrderFlag,
        c.PersonID,

        CASE
            WHEN soh.CreditCardID IS NULL
                THEN 'No card used'

            WHEN c.PersonID IS NULL
                THEN 'Customer card ownership unavailable'

            WHEN EXISTS (
                SELECT 1
                FROM personcreditcard AS pcc
                WHERE pcc.BusinessEntityID = c.PersonID
                  AND pcc.CreditCardID = soh.CreditCardID
            )
                THEN 'Registered customer card'

            ELSE 'Card not registered to customer'
        END AS card_verification_status

    FROM salesorderheader AS soh

    LEFT JOIN customer AS c
        ON soh.CustomerID = c.CustomerID
)

SELECT
    card_verification_status,
    COUNT(*) AS transaction_count

FROM payment_verification

GROUP BY card_verification_status
ORDER BY transaction_count DESC;


-- 4. Credit cards associated with multiple customers

SELECT
    pcc.CreditCardID,
    cc.CardType,

    COUNT(
        DISTINCT c.CustomerID
    ) AS associated_customer_count

FROM personcreditcard AS pcc

INNER JOIN customer AS c
    ON pcc.BusinessEntityID = c.PersonID

LEFT JOIN creditcard AS cc
    ON pcc.CreditCardID = cc.CreditCardID

GROUP BY
    pcc.CreditCardID,
    cc.CardType

HAVING COUNT(DISTINCT c.CustomerID) > 1

ORDER BY associated_customer_count DESC;

-- 5. Selected geographic risk indicators

WITH geographic_features AS (
    SELECT
        soh.SalesOrderID,
        soh.CustomerID,
        soh.OrderDate,
        soh.TotalDue,
        soh.OnlineOrderFlag,
        soh.CreditCardID,

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

    FROM salesorderheader AS soh

    LEFT JOIN address AS bill
        ON soh.BillToAddressID = bill.AddressID

    LEFT JOIN address AS ship
        ON soh.ShipToAddressID = ship.AddressID
)

SELECT
    SalesOrderID,
    CustomerID,
    OrderDate,
    ROUND(TotalDue, 2) AS order_value,
    OnlineOrderFlag,
    CreditCardID,

    billing_city,
    billing_state,
    shipping_city,
    shipping_state,

    billing_shipping_city_mismatch_flag,
    billing_shipping_state_mismatch_flag

FROM geographic_features

WHERE billing_shipping_city_mismatch_flag = 1
   OR billing_shipping_state_mismatch_flag = 1

ORDER BY
    billing_shipping_state_mismatch_flag DESC,
    order_value DESC;