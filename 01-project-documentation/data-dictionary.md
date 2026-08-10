# Fraud Analytics Data Dictionary

This document describes the principal fields used throughout the fraud analytics workflow.

The dictionary focuses on variables used for transaction analysis, behavioural risk detection, anomaly modelling and Tableau investigation dashboards.

## Transaction Identifiers

| Field | Description |
|---|---|
| `Order ID` | Unique identifier for each transaction. |
| `Customer ID` | Unique identifier for the customer associated with the transaction. |
| `Order Date` | Date on which the transaction occurred. |
| `Online Order Flag` | Indicates whether the transaction was completed through the online channel. |

## Transaction Value

| Field | Description |
|---|---|
| `Order Value` | Total monetary value of the transaction. |
| `Prior Avg Order Value` | Average value of the customer's previous transactions prior to the current order. |
| `Amount Vs Customer Avg` | Ratio between the current transaction value and the customer's historical average transaction value. |
| `Log Order Value` | Log-transformed transaction value used during exploratory analysis and anomaly modelling. |

## Customer Behaviour

| Field | Description |
|---|---|
| `Previous Order Date` | Date of the customer's immediately preceding transaction. |
| `Days Since Previous Order` | Number of days between the current transaction and the previous customer transaction. |
| `Prior Order Count` | Number of transactions completed by the customer before the current transaction. |
| `Same Day Repeat Flag` | Indicates whether another customer transaction occurred on the same day. |
| `Rapid Repeat Flag` | Indicates whether another transaction occurred within 1–7 days of the previous order. |

## Transaction Risk Indicators

| Field | Description |
|---|---|
| `Amount Spike Flag` | Identifies transactions at least three times greater than the customer's historical average when sufficient history is available. |
| `City Mismatch Flag` | Indicates a city-level inconsistency between relevant transaction locations. |
| `State Mismatch Flag` | Indicates a state or province inconsistency between relevant transaction locations. |
| `Geographic Mismatch Flag` | Consolidated indicator representing the presence of a geographic inconsistency. |

## Rule-Based Risk Framework

| Field | Description |
|---|---|
| `Velocity Risk Points` | Risk points generated from transaction-frequency behaviour such as same-day or rapid repeat purchases. |
| `Behavioural Risk Points` | Risk points generated from deviations from customer purchasing behaviour, including amount spikes. |
| `Geographic Risk Points` | Risk contribution generated from geographic inconsistencies. |
| `Risk Score` | Combined rule-based transaction risk score used to prioritise transactions for investigation. |
| `Risk Level` | Investigation priority classification: Low, Medium or High. |
| `Risk Reason` | Human-readable explanation of the risk indicators triggered by the transaction. |
| `High Risk Flag` | Binary indicator identifying transactions classified as High risk. |
| `Flagged Transaction Flag` | Binary indicator identifying transactions with rule-based risk signals requiring additional review. |

## Anomaly Detection

| Field | Description |
|---|---|
| `Model Eligible Flag` | Indicates whether sufficient customer history exists for behavioural anomaly modelling. |
| `Anomaly Score` | Continuous Isolation Forest score representing how statistically unusual a transaction is relative to the modelling population. |
| `Anomaly Percentile` | Percentile ranking derived from the anomaly score. Higher values represent more unusual transactions. |
| `Top 1% Anomaly Flag` | Identifies transactions ranked within the most unusual 1% of model-eligible transactions. |
| `Top 5% Anomaly Flag` | Identifies transactions ranked within the most unusual 5% of model-eligible transactions. |
| `Top 10% Anomaly Flag` | Identifies transactions ranked within the most unusual 10% of model-eligible transactions. |

## Behaviour-Focused Anomaly Detection

| Field | Description |
|---|---|
| `Behaviour Anomaly Score` | Isolation Forest anomaly score produced by the behaviour-focused model. |
| `Behaviour Anomaly Percentile` | Percentile ranking of the behaviour-focused anomaly score. |
| `Behaviour Top 1Pct` | Identifies transactions within the top 1% of behavioural anomalies. |
| `Behaviour Top 5Pct` | Identifies transactions within the top 5% of behavioural anomalies. |
| `Behaviour Top 10Pct` | Identifies transactions within the top 10% of behavioural anomalies. |

## Geographic Information

| Field | Description |
|---|---|
| `Billing City` | City associated with the transaction billing information. |
| `Billing State` | State or province associated with the billing information. |
| `Shipping City` | City associated with the transaction delivery destination. |
| `Shipping State` | State or province associated with the delivery destination. |

## Dashboard Usage

The Tableau reporting layer uses a subset of these fields to support two primary analytical views:

**Risk Overview**

- Total transactions
- Flagged transactions
- High-risk transactions
- Model-eligible transactions
- Risk Level
- Risk indicators
- Flagged transaction rate

**Transaction Investigation**

- Risk Score
- Anomaly Percentile
- Order ID
- Customer ID
- Risk Level
- Risk Reason
- Order Value
- Days Since Prior Order

Together, these fields provide both an aggregated monitoring layer and transaction-level investigation capability.
