# Project Documentation

## Business Problem

Fraud investigation teams may need to analyse large volumes of transactions while having limited capacity to manually review every case.

This project develops an analytical workflow to identify suspicious transaction behaviour, prioritise potentially risky transactions and support investigation through SQL, Python and Tableau.

## Project Objectives

- Analyse transactional behaviour using SQL.
- Develop rule-based fraud risk indicators.
- Identify unusual transactions using anomaly detection techniques in Python.
- Combine analytical outputs into a prioritised investigation workflow.
- Build interactive Tableau dashboards for fraud monitoring and transaction investigation.

## Analytical Workflow

Raw Transaction Data
        ↓
Data Quality & Preparation
        ↓
SQL Transaction Analysis
        ↓
Risk Indicators
        ↓
Python Anomaly Detection
        ↓
Risk Prioritisation
        ↓
Tableau Monitoring & Investigation

## Risk Indicators

The analysis currently considers behavioural indicators such as:

- Rapid repeat transactions
- Same-day repeat transactions
- Unusual transaction value / amount spikes
- City mismatch
- State or province mismatch

These indicators are used to create a transaction-level risk score and provide interpretable reasons for why a transaction has been flagged.

## Investigation Approach

Transactions are prioritised using several complementary signals rather than relying on a single fraud rule.

The investigation layer combines:

**Risk Score**  
Number/severity of triggered behavioural risk indicators.

**Risk Level**  
Categorisation of transactions into Low, Medium and High risk.

**Anomaly Detection**  
Python-based analysis used to identify transactions exhibiting unusual behaviour.

**Risk Reason**  
Human-readable explanation of the indicators responsible for flagging a transaction.

This creates a prioritised investigation queue where analysts can focus on transactions presenting stronger or multiple risk signals.

## Technology Stack

| Stage | Technology |
|---|---|
| Data preparation | SQL |
| Transaction analysis | SQL |
| Risk indicators | SQL |
| Anomaly detection | Python |
| Data manipulation | pandas |
| Investigation dashboards | Tableau |
| Version control | Git / GitHub |

## Current Deliverables

- SQL exploratory and transactional analysis
- Fraud risk indicators
- Python anomaly detection analysis
- Risk scoring and prioritisation
- Risk Overview dashboard
- Transaction Investigation dashboard
- Interactive investigation queue

## Project Status

The project is currently under active development. Additional behavioural analysis, model validation and dashboard functionality will be added in subsequent iterations.
