# SQL Fraud Detection & Transaction Risk Analytics

This folder contains the SQL analytical pipeline developed for the fraud detection and transaction risk analytics project.

The objective of the SQL layer is to transform raw transactional data into a structured risk-analysis dataset by combining data validation, customer behavioural baselines, transaction pattern analysis, feature engineering and an interpretable rule-based risk scoring framework.

> The source dataset does not contain confirmed fraud labels. Therefore, the project identifies suspicious and unusual transaction patterns rather than claiming to predict confirmed fraud.

## SQL Pipeline

```text
     Raw Data
        │
        ▼
01. Data Source Audit
        │
        ▼
02. Data Quality Checks
        │
        ▼
03. Customer Transaction Baselines
        │
        ▼
04. Transaction Pattern Analysis
        │
        ▼
05. Payment & Geographic Risk
        │
        ▼
06. Fraud Risk Feature Engineering
        │
        ▼
07. Transaction Risk Scoring
        │
        ▼
08. Analytical Views
        │
        ▼
09. Analytics Dataset
        │
        ├── Python Anomaly Detection
        │
        └── Tableau Dashboards

```

## Key SQL Techniques

- Multi-table joins
- Common Table Expressions (CTEs)
- Nested analytical pipelines
- Subqueries
- Conditional aggregation
- `CASE WHEN`
- `LAG()`
- `ROW_NUMBER()`
- Windowed `COUNT()` and `AVG()`
- Historical rolling windows
- Customer behavioural baselines
- Risk feature engineering
- Analytical views
- Reporting-ready dataset design

## 01 — Data Source Audit

**File:** `01_data_source_audit.sql`

The first stage evaluates the database structure and identifies the tables relevant to transaction-risk analysis.

The audit focuses primarily on customer, sales-order, credit-card and address data, while also examining transaction coverage, table volumes, purchasing frequency and the relationships between customers, payment methods and billing/shipping locations.

This stage establishes whether the available transaction history and relational structure are sufficient to support behavioural risk analysis.

## 02 — Data Quality Checks

**File:** `02_data_quality_checks.sql`

Before developing risk indicators, the core transaction data is validated to ensure that suspicious patterns are not simply the result of poor data quality.

The checks cover duplicate orders, missing transaction fields, invalid transaction values, inconsistent order dates and broken relationships between transactions, customers, credit cards and addresses.

The core transaction fields were found to be highly complete, allowing the subsequent behavioural analysis to be performed on a reliable transaction base.

## 03 — Customer Transaction Baselines

**File:** `03_customer_transaction_baselines.sql`

Customer behaviour is evaluated relative to each customer's own transaction history rather than relying only on global transaction thresholds.

SQL window functions are used to reconstruct transaction sequences and calculate historical behavioural baselines for every order.

Key derived measures include:

- previous transaction date;
- days since the previous transaction;
- number of prior transactions;
- historical average transaction value;
- historical maximum transaction value;
- current transaction value relative to the customer's previous average.

This allows the analysis to distinguish between transactions that are globally large and transactions that are unusually large for a specific customer.

## 04 — Transaction Pattern Analysis

**File:** `04_transaction_pattern_analysis.sql`

This stage investigates transaction velocity and deviations from historical customer behaviour.

The analysis evaluates same-day repeat activity, transactions occurring within seven days of a previous purchase and unusually large transactions relative to each customer's historical spending level.

An amount-spike condition is defined when a customer has at least two previous transactions and the current transaction value is at least three times the customer's historical average.

## 05 — Payment & Geographic Risk

**File:** `05_payment_and_geographic_risk.sql`

Payment and geographic relationships are analysed as additional sources of transaction context.

Billing and shipping locations are compared at city and state/province level, while customer-to-credit-card relationships are evaluated to identify potentially unusual payment behaviour.

Candidate indicators were tested before inclusion in the final framework. Features that showed insufficient variation or analytical value were not forced into the scoring model.

## 06 — Fraud Risk Feature Engineering

**File:** `06_fraud_risk_features.sql`

The behavioural and geographic analyses are consolidated into transaction-level risk indicators.

The final rule-based features include:

- `same_day_repeat_flag`
- `rapid_repeat_flag`
- `amount_spike_flag`
- `city_mismatch_flag`
- `state_mismatch_flag`

Feature combinations are also analysed to identify transactions presenting multiple independent risk signals.

Particular attention is given to avoiding double counting. Related indicators such as same-day versus rapid-repeat activity, or city versus state mismatches, are treated as hierarchical signals rather than automatically counted as independent risks.

## Analytical Design Approach

The risk framework was designed around three principles:

1. **Customer context over global thresholds**  
   Transactions are evaluated relative to each customer's previous behaviour whenever possible.

2. **Multiple independent signals over isolated anomalies**  
   Higher investigation priority is assigned when behavioural, velocity or geographic indicators occur together.

3. **Interpretability over black-box scoring**  
   Every risk score can be traced back to specific transaction-level indicators and summarised through a human-readable `risk_reason`.

## 07 — Transaction Risk Scoring

**File:** `07_transaction_risk_scoring.sql`

An interpretable heuristic scoring framework converts the engineered indicators into transaction-prioritisation scores.

| Risk Dimension | Condition | Points |
|---|---|---:|
| Velocity | Same-day repeat | 2 |
| Velocity | Repeat within 1–7 days | 1 |
| Behaviour | Transaction ≥3× historical customer average | 3 |
| Geography | Different city | 1 |
| Geography | Different state/province | 2 |

Related indicators are mutually prioritised to prevent double counting.

### Risk Classification

| Score | Risk Level |
|---:|---|
| 0 | Low |
| 1–3 | Medium |
| 4+ | High |

### Resulting Distribution

From **31,465 transactions**:

| Risk Level | Transactions | Share |
|---|---:|---:|
| Low | 30,853 | 98.05% |
| Medium | 602 | 1.91% |
| High | 10 | 0.03% |

The score represents transaction investigation priority rather than a probability of fraud.

### Key Finding

High-priority transactions were not necessarily the transactions with the highest absolute values.

Several transactions were prioritised because their values were unusually large relative to the individual customer's historical behaviour and occurred shortly after previous purchases.

This highlights the value of behavioural baselines compared with simple global transaction-value thresholds.

## 08 — Analytical Views

**File:** `08_analytical_views.sql`

Reusable analytical views are created so downstream applications do not need to reproduce the full SQL feature-engineering and scoring pipeline.

The main views are:

- `vw_transaction_risk_analysis`
- `vw_high_risk_transactions`
- `vw_risk_level_summary`
- `vw_customer_risk_summary`

`vw_transaction_risk_analysis` provides the complete transaction-level analytical layer.

`vw_high_risk_transactions` creates a prioritised investigation queue.

`vw_risk_level_summary` supports risk-level KPIs and reporting.

`vw_customer_risk_summary` provides a customer-level perspective on accumulated anomalous behaviour.

## 09 — Analytics Dataset

**File:** `09_analytics_dataset.sql`

The final SQL stage creates `vw_fraud_analytics_dataset`, which acts as the interface between the relational analysis and the downstream Python and Tableau layers.

The final dataset preserves all **31,465 transactions** and enriches them with:

- temporal reporting fields;
- customer behavioural baselines;
- transaction-velocity indicators;
- behavioural deviation indicators;
- geographic indicators;
- individual risk components;
- overall transaction risk score;
- risk classification;
- human-readable risk reasons.

## Next Stage

The SQL analytical dataset is used as the foundation for two downstream components:

### Python

Unsupervised anomaly detection is used to identify unusual transactions from a data-driven perspective and compare those findings with the transparent SQL rule-based scoring framework.

### Tableau

Interactive dashboards are developed for transaction-risk monitoring, investigation prioritisation, customer analysis and risk-pattern exploration.

