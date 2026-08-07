-- ============================================================
-- FRAUD DETECTION & TRANSACTION RISK ANALYTICS
-- 01 - DATA SOURCE AUDIT
-- ============================================================

USE adventureworks2017;


-- 1. Fraud-relevant source tables

SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'adventureworks2017'
  AND (
       table_name LIKE '%customer%'
    OR table_name LIKE '%salesorder%'
    OR table_name LIKE '%creditcard%'
    OR table_name LIKE '%personcredit%'
    OR table_name LIKE '%purchaseorder%'
    OR table_name LIKE '%vendor%'
    OR table_name LIKE '%transactionhistory%'
    OR table_name LIKE '%employee%'
    OR table_name LIKE '%address%'
  )
ORDER BY table_name;


-- 2. Core table structures

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'adventureworks2017'
  AND table_name IN (
      'customer',
      'creditcard',
      'personcreditcard',
      'salesorderheader',
      'salesorderdetail',
      'address'
  )
ORDER BY
    table_name,
    ordinal_position;


-- 3. Core table volumes

SELECT
    (SELECT COUNT(*) FROM customer) AS customer_rows,
    (SELECT COUNT(*) FROM creditcard) AS creditcard_rows,
    (SELECT COUNT(*) FROM personcreditcard) AS personcreditcard_rows,
    (SELECT COUNT(*) FROM salesorderheader) AS salesorderheader_rows,
    (SELECT COUNT(*) FROM salesorderdetail) AS salesorderdetail_rows,
    (SELECT COUNT(*) FROM address) AS address_rows;


-- 4. Transaction coverage

SELECT
    MIN(OrderDate) AS first_order_date,
    MAX(OrderDate) AS last_order_date,
    COUNT(*) AS total_orders,
    COUNT(DISTINCT CustomerID) AS active_customers
FROM salesorderheader;


-- 5. Order value baseline

SELECT
    ROUND(MIN(TotalDue), 2) AS min_order_value,
    ROUND(AVG(TotalDue), 2) AS avg_order_value,
    ROUND(MAX(TotalDue), 2) AS max_order_value,
    ROUND(SUM(TotalDue), 2) AS total_order_value
FROM salesorderheader;


-- 6. Customer purchasing behaviour

SELECT
    CustomerID,
    COUNT(*) AS order_count,
    ROUND(AVG(TotalDue), 2) AS avg_order_value,
    ROUND(MAX(TotalDue), 2) AS max_order_value,
    ROUND(SUM(TotalDue), 2) AS total_spend
FROM salesorderheader
GROUP BY CustomerID
ORDER BY order_count DESC;


-- 7. Customer order frequency distribution

WITH customer_order_summary AS (
    SELECT
        CustomerID,
        COUNT(*) AS order_count
    FROM salesorderheader
    GROUP BY CustomerID
)

SELECT
    order_count,
    COUNT(*) AS customer_count
FROM customer_order_summary
GROUP BY order_count
ORDER BY order_count;


-- 8. Customer credit-card relationships

SELECT
    c.CustomerID,
    c.PersonID,
    pcc.CreditCardID,
    cc.CardType,
    cc.ExpMonth,
    cc.ExpYear
FROM customer AS c
LEFT JOIN personcreditcard AS pcc
    ON c.PersonID = pcc.BusinessEntityID
LEFT JOIN creditcard AS cc
    ON pcc.CreditCardID = cc.CreditCardID
WHERE c.PersonID IS NOT NULL
ORDER BY
    c.CustomerID,
    pcc.CreditCardID
LIMIT 100;


-- 9. Billing and shipping relationships

SELECT
    soh.SalesOrderID,
    soh.CustomerID,
    ROUND(soh.TotalDue, 2) AS order_value,
    soh.BillToAddressID,
    bill.City AS billing_city,
    bill.StateProvinceID AS billing_state,
    soh.ShipToAddressID,
    ship.City AS shipping_city,
    ship.StateProvinceID AS shipping_state
FROM salesorderheader AS soh
LEFT JOIN address AS bill
    ON soh.BillToAddressID = bill.AddressID
LEFT JOIN address AS ship
    ON soh.ShipToAddressID = ship.AddressID
ORDER BY soh.SalesOrderID
LIMIT 100;