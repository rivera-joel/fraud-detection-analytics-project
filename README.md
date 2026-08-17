# Fraud Detection & Transaction Risk Analytics

**End-to-end fraud analytics project using SQL, Python and Tableau to transform raw transactional data into an interpretable risk-monitoring and investigation workflow.**

| Transactions Analysed | Medium Priority | High Priority | BI Output                   |
| --------------------: | ---------------------: | ------------: | --------------------------- |
|            **31,465** |        **612 (1.95%)** |        **10** | **5 analytical dashboards** |


---

<p align="center">
  <img
    src="https://img.shields.io/badge/SQL-336791?style=for-the-badge&logo=postgresql&logoColor=white"
    alt="SQL"
  />
  &nbsp;
  <img
    src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white"
    alt="Python"
  />
  &nbsp;
  <img
    src="https://img.shields.io/badge/Tableau-E97627?style=for-the-badge&logo=tableau&logoColor=white"
    alt="Tableau"
  />
  &nbsp;
  <img
    src="https://img.shields.io/badge/Pandas-150458?style=for-the-badge&logo=pandas&logoColor=white"
    alt="Pandas"
  />
  &nbsp;
  <img
    src="https://img.shields.io/badge/Jupyter-F37626?style=for-the-badge&logo=jupyter&logoColor=white"
    alt="Jupyter"
  />
</p>

## Executive Summary

Fraud investigation teams cannot manually review every transaction with the same level of attention.

This project develops an end-to-end analytical workflow that transforms raw transactional data into a prioritised investigation dataset by combining:

* **SQL** for data validation, behavioural analysis, feature engineering and rule-based risk scoring.
* **Python** for exploratory analysis and unsupervised anomaly detection.
* **Tableau** for risk monitoring, transaction investigation and customer-level analysis.

The objective is not simply to flag high-value transactions, but to identify activity that is **unusual relative to the customer's own historical behaviour** and combine multiple independent risk signals into an interpretable investigation framework.

> **Important:** The source dataset does not contain confirmed fraud labels. Therefore, the project identifies suspicious or anomalous transaction patterns and investigation priorities rather than claiming to predict confirmed fraud.

---

## Key Results & Insights

### 1. Investigation can be concentrated on a small subset of transactions

From **31,465 transactions**, the rule-based risk framework classified:

| Risk Level | Transactions |  Share |
| ---------- | -----------: | -----: |
| Low        |       30,853 | 98.05% |
| Medium     |          602 |  1.91% |
| High       |           10 |  0.03% |

This concentrates investigation on approximately **1.95% of the transaction population**, allowing analysts to prioritise cases presenting stronger risk signals rather than reviewing the full dataset uniformly.

### 2. High transaction value alone was not the strongest risk signal

High-priority transactions were not necessarily those with the largest absolute transaction values.

Several transactions became more relevant because their values were **unusually high relative to that customer's previous behaviour**, particularly when combined with short intervals between purchases.

This demonstrates why behavioural baselines can provide more meaningful investigation context than simple global value thresholds.

### 3. Combining signals provides stronger investigation context

The framework evaluates multiple dimensions of suspicious behaviour:

* Same-day repeat transactions
* Rapid repeat transactions
* Transaction amount spikes
* Billing / shipping city mismatches
* State or province mismatches

Higher investigation priority is assigned when independent behavioural, velocity and geographic indicators occur together.

Related indicators are handled hierarchically to avoid artificially inflating risk scores through double counting.

### 4. Explainability was prioritised over black-box scoring

Every prioritised transaction retains a human-readable **risk reason** explaining why the transaction was flagged.

This allows an investigator to move from:

**Risk Score → Triggered Indicators → Customer Behaviour → Transaction Detail**

rather than relying on an unexplained model output.

---

## Business Impact

The project demonstrates how analytics can convert a large transaction population into a structured fraud-investigation workflow.

### Investigation prioritisation

Instead of treating all **31,465 transactions** equally, the analytical layer surfaces a much smaller group requiring additional attention.

### Behaviour-based monitoring

Customer-specific historical baselines help identify transactions that may appear normal globally but are abnormal for the individual customer.

### Explainable decision support

Risk scores are accompanied by the underlying reasons and indicators, allowing investigators to understand why a transaction has been prioritised.

### Reusable analytics layer

SQL analytical views create a consistent dataset that can be reused by both Python analysis and Tableau reporting without rebuilding the risk logic downstream.

### Investigation-oriented Business Intelligence

The Tableau solution translates analytical outputs into a navigable workflow from high-level monitoring to individual transaction and customer investigation.

---

## End-to-End Analytical Workflow

```text
Raw Transaction Data
        ↓
SQL Data Validation & Quality Checks
        ↓
Customer Behavioural Baselines
        ↓
Transaction Pattern Analysis
        ↓
Risk Feature Engineering
        ↓
Rule-Based Risk Scoring
        ↓
Python Anomaly Detection
        ↓
Risk Prioritisation
        ↓
Tableau Monitoring & Investigation
        ↓
Business Insights & Investigation Decisions
```

---

## SQL Analytics

The SQL layer transforms relational transaction data into an investigation-ready analytical dataset.

Key techniques include:

* Multi-table joins
* Common Table Expressions (CTEs)
* Window functions
* `LAG()`
* `ROW_NUMBER()`
* Conditional aggregation
* Historical behavioural baselines
* Feature engineering
* Analytical views
* Transaction-level risk scoring

The final SQL dataset preserves all **31,465 transactions** while enriching them with behavioural, velocity, geographic and risk-scoring features.

➡️ [View SQL Analysis](./02-sql-data-analysis/)

---

## Python Fraud Analysis

Python provides a complementary data-driven perspective to the transparent SQL risk framework.

The analytical layer includes:

* Data validation with pandas
* Exploratory Data Analysis
* Feature analysis
* Anomaly detection
* Comparison of anomalous activity with rule-based risk indicators
* Business-focused interpretation of suspicious patterns

The objective is to investigate whether unusual transactions identified statistically align with the behavioural signals identified through SQL.

➡️ [View Python Analysis](./03-python-fraud-analysis/)

---

## Tableau Risk Analytics

The final analytical layer converts the fraud-risk outputs into an interactive investigation-oriented BI solution.

The Tableau suite includes:

1. **Risk Overview**
2. **Transaction Investigation**
3. **Behavioural Risk**
4. **Geographic Risk**
5. **Customer Risk**

The dashboards allow users to move from overall transaction-risk monitoring to individual transaction and customer investigation.

➡️ [View Tableau Dashboards](./04-tableau-dashboard/)

---

## Repository Structure

```text
fraud-detection-analytics-project/
│
├── 01-project-documentation/
│   ├── Fraud Analytics Data Model Schema.png
│   ├── Fraud-Analytics-Workflow.png
│   ├── data-dictionary.md
│   ├── risk-methodology.md
│   └── README.md
│
├── 02-sql-data-analysis/
│   ├── 01_data_source_audit.sql
│   ├── 02_data_quality_checks.sql
│   ├── 03_customer_transaction_baselines.sql
│   ├── 04_transaction_pattern_analysis.sql
│   ├── 05_payment_and_geographic_risk.sql
│   ├── 06_fraud_risk_features.sql
│   ├── 07_transaction_risk_scoring.sql
│   ├── 08_analytical_views.sql
│   ├── 09_analytics_dataset.sql
│   └── README.md
│
├── 03-python-fraud-analysis/
│   ├── 01_fraud_anomaly_detection_analysis.ipynb
│   ├── 01_fraud_anomaly_detection_analysis.py
│   └── README.md
│
├── 04-tableau-dashboard/
│   ├── dashboard-previews/
│   ├── Dashboards-BI.pdf
│   └── README.md
│
└── README.md
```

---

## Tools & Techniques

**SQL · Python · pandas · Tableau · EDA · Feature Engineering · Anomaly Detection · Business Intelligence · Fraud Analytics · Risk Analytics**

---

## Analytical Limitations

The dataset does not contain confirmed fraudulent / non-fraudulent transaction labels.

As a result:

* Risk scores represent **investigation priority**, not fraud probability.
* Anomaly detection identifies unusual behaviour, not confirmed fraudulent behaviour.
* The framework should be interpreted as a decision-support and prioritisation system rather than a production fraud-classification model.

A production implementation could extend the framework using confirmed investigation outcomes, supervised fraud labels and continuous model-performance monitoring.

---

## Usage and Copyright
```

This repository is published for portfolio and educational purposes only.

You may view, download and reference this repository for learning purposes, but redistribution, reproduction, modification or commercial use of the contents without prior written permission is not permitted.

© 2026 Joel Rivera Garmendia. All rights reserved.

