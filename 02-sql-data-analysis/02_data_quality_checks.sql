-- ============================================================
-- FRAUD DETECTION & TRANSACTION RISK ANALYTICS
-- 02 - DATA QUALITY CHECKS
-- ============================================================

USE adventureworks2017;


-- 1. Duplicate sales orders

SELECT
    SalesOrderID,
    COUNT(*) AS record_count
FROM salesorderheader
GROUP BY SalesOrderID
HAVING COUNT(*) > 1;


-- 2. Missing core transaction fields

SELECT
    SUM(CASE WHEN SalesOrderID IS NULL THEN 1 ELSE 0 END) AS missing_sales_order_id,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS missing_order_date,
    SUM(CASE WHEN TotalDue IS NULL THEN 1 ELSE 0 END) AS missing_total_due,
    SUM(CASE WHEN BillToAddressID IS NULL THEN 1 ELSE 0 END) AS missing_billing_address,
    SUM(CASE WHEN ShipToAddressID IS NULL THEN 1 ELSE 0 END) AS missing_shipping_address
FROM salesorderheader;


-- 3. Invalid transaction values

SELECT
    COUNT(*) AS invalid_order_values
FROM salesorderheader
WHERE TotalDue <= 0;


-- 4. Order date consistency

SELECT
    SalesOrderID,
    OrderDate,
    DueDate,
    ShipDate
FROM salesorderheader
WHERE DueDate < OrderDate
   OR ShipDate < OrderDate;


-- 5. Orders linked to missing customers

SELECT
    soh.SalesOrderID,
    soh.CustomerID
FROM salesorderheader AS soh
LEFT JOIN customer AS c
    ON soh.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;


-- 6. Orders linked to missing credit cards

SELECT
    soh.SalesOrderID,
    soh.CustomerID,
    soh.CreditCardID,
    soh.OnlineOrderFlag
FROM salesorderheader AS soh
LEFT JOIN creditcard AS cc
    ON soh.CreditCardID = cc.CreditCardID
WHERE soh.CreditCardID IS NOT NULL
  AND cc.CreditCardID IS NULL;


-- 7. Orders linked to missing addresses

SELECT
    soh.SalesOrderID,
    soh.BillToAddressID,
    soh.ShipToAddressID
FROM salesorderheader AS soh
LEFT JOIN address AS bill
    ON soh.BillToAddressID = bill.AddressID
LEFT JOIN address AS ship
    ON soh.ShipToAddressID = ship.AddressID
WHERE bill.AddressID IS NULL
   OR ship.AddressID IS NULL;


-- 8. Credit-card usage coverage

SELECT
    OnlineOrderFlag,
    COUNT(*) AS order_count,
    SUM(
        CASE
            WHEN CreditCardID IS NULL THEN 1
            ELSE 0
        END
    ) AS orders_without_card,
    SUM(
        CASE
            WHEN CreditCardID IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS orders_with_card
FROM salesorderheader
GROUP BY OnlineOrderFlag
ORDER BY OnlineOrderFlag;


-- 9. Customer transaction coverage

SELECT
    COUNT(DISTINCT c.CustomerID) AS total_customers,
    COUNT(DISTINCT soh.CustomerID) AS customers_with_orders,
    COUNT(
        DISTINCT CASE
            WHEN soh.CustomerID IS NULL THEN c.CustomerID
        END
    ) AS customers_without_orders
FROM customer AS c
LEFT JOIN salesorderheader AS soh
    ON c.CustomerID = soh.CustomerID;