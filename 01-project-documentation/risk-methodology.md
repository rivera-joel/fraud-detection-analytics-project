# Fraud Risk Methodology

## 1. Methodology Overview

This project uses a layered transaction-risk methodology combining transparent rule-based detection with unsupervised anomaly detection.

The objective is not to classify transactions as confirmed fraud. Instead, the framework identifies behavioural patterns and statistical anomalies that may warrant further investigation.

The methodology consists of four main stages:

1. Customer behavioural baseline construction
2. Rule-based transaction risk indicators
3. Transaction risk scoring and prioritisation
4. Independent behavioural anomaly detection using Isolation Forest

The outputs are subsequently combined within an investigation workflow to help prioritise transactions presenting stronger or multiple risk signals.

---

## 2. Customer Behavioural Baseline

Transaction risk is evaluated relative to each customer's historical purchasing behaviour rather than relying exclusively on global transaction thresholds.

For every transaction, historical features are calculated using only previous customer activity.

Key behavioural variables include:

- `days_since_previous_order`
- `prior_order_count`
- `prior_avg_order_value`
- `amount_vs_customer_avg`

### Days Since Previous Order

Measures the number of days between the current transaction and the customer's previous transaction.

This allows unusually rapid purchasing behaviour to be identified.

### Prior Order Count

Represents the number of transactions completed by the customer before the current transaction.

This variable is also used to determine whether sufficient historical behaviour exists for anomaly modelling.

### Prior Average Order Value

Represents the customer's historical average transaction value before the current purchase.

### Amount vs Customer Average

Measures the size of the current transaction relative to the customer's historical average:

Current Transaction Value / Historical Customer Average

This customer-specific benchmark allows large behavioural deviations to be identified without assuming that the same absolute transaction value is unusual for every customer.

---

## 3. Rule-Based Risk Indicators

Five interpretable transaction-risk indicators are generated.

### 3.1 Same-Day Repeat

Triggered when another transaction from the same customer occurred on the same day.

This represents the strongest transaction-velocity signal in the rule-based framework.

**Risk points: 2**

---

### 3.2 Rapid Repeat

Triggered when a customer completes another transaction within 1–7 days of the previous transaction.

This captures unusually short purchasing intervals without treating them as strongly as same-day activity.

**Risk points: 1**

---

### 3.3 Amount Spike

Triggered when:

- the customer has sufficient transaction history; and
- the current transaction value is at least 3 times the customer's historical average.

This indicator captures unusually large deviations from customer-specific spending behaviour rather than simply identifying globally high-value transactions.

**Risk points: 3**

---

### 3.4 City Mismatch

Triggered when the relevant billing and shipping location information contains a city-level inconsistency.

This provides a geographic risk signal that may support further transaction review.

---

### 3.5 State / Province Mismatch

Triggered when the relevant billing and shipping information contains a state or province inconsistency.

City and state/province mismatches form the geographic risk dimension.

**Geographic risk contribution: 1 point**

---

## 4. Transaction Risk Score

The indicators are combined into an interpretable transaction-level risk score.

The scoring framework gives greater weight to behavioural signals that represent stronger deviations from normal customer activity.

| Risk Component | Points |
|---|---:|
| Same-day repeat | 2 |
| Rapid repeat (1–7 days) | 1 |
| Amount spike | 3 |
| Geographic mismatch | 1 |

The maximum observed transaction risk score is **5**.

For example:

| Behaviour | Risk Score |
|---|---:|
| No risk indicators | 0 |
| Rapid repeat | 1 |
| Same-day repeat | 2 |
| Amount spike | 3 |
| Rapid repeat + Amount spike | 4 |
| Same-day repeat + Amount spike | 5 |

The purpose of the score is prioritisation rather than fraud classification.

A higher score indicates that the transaction presents stronger or multiple investigation signals.

---

## 5. Risk Level Classification

The transaction risk score is converted into three investigation-priority levels.

| Risk Score | Risk Level | Interpretation |
|---|---|---|
| 0 | Low | No rule-based risk indicators |
| 1–3 | Medium | One or more moderate risk indicators |
| 4–5 | High | Strong combination of behavioural risk indicators |

This produces a highly selective High-risk category while retaining Medium-risk transactions for broader monitoring and investigation.

---

## 6. Risk Reason

Alongside the numerical risk score, each flagged transaction receives a human-readable `risk_reason`.

Examples include:

- `Rapid repeat (1-7 days)`
- `Same-day repeat`
- `Amount spike`
- `City mismatch`
- `State/province mismatch`
- `Rapid repeat (1-7 days), Amount spike`
- `Same-day repeat, Amount spike`

Transactions without triggered indicators are labelled:

`No risk indicators`

This makes the framework interpretable for investigators because the reason behind each risk score can be directly identified.

---

## 7. Independent Anomaly Detection

A second analytical layer uses unsupervised machine learning to identify statistically unusual transaction behaviour.

The model uses **Isolation Forest**.

Importantly, the model does not use:

- the rule-based risk score;
- the assigned Risk Level; or
- the rule-generated risk flags.

This separation prevents information leakage and allows the anomaly model to provide an independent perspective on transaction behaviour.

---

## 8. Model Eligibility

Behavioural anomaly detection requires previous customer activity.

A customer's first observed transaction does not contain:

- a previous transaction date;
- historical order frequency; or
- a historical spending baseline.

Rather than artificially imputing this information, first transactions are excluded from model training.

Transactions are therefore considered model eligible when:

`prior_order_count > 0`

All transactions remain available within the complete analytical dataset, while a `model_eligible_flag` identifies which transactions received behavioural anomaly scoring.

---

## 9. Initial Isolation Forest Model

The initial anomaly model uses the following features:

- `order_value`
- `days_since_previous_order`
- `prior_order_count`
- `prior_avg_order_value`
- `amount_vs_customer_avg`
- `OnlineOrderFlag`

Highly skewed numerical variables are log-transformed before modelling.

The transformed features are subsequently standardised using `StandardScaler`.

The Isolation Forest configuration uses:

- 300 estimators
- automatic contamination threshold
- random state = 42

The model generates a continuous `anomaly_score` for each eligible transaction.

A larger anomaly score indicates behaviour that is increasingly unusual relative to the modelling population.

---

## 10. Anomaly Percentile

Because the automatic Isolation Forest classification identifies a relatively broad anomaly population, the continuous anomaly score is used as the primary prioritisation signal.

Transactions are ranked according to their anomaly score to create an anomaly percentile.

The percentile makes interpretation easier:

- Top 10% → unusually high anomaly ranking
- Top 5% → stronger anomaly signal
- Top 1% → most statistically unusual transactions

This approach supports investigation prioritisation without treating the model output as a definitive fraud classification.

---

## 11. Behaviour-Focused Isolation Forest

Analysis of the initial Isolation Forest showed that some statistically unusual customer profiles were not necessarily meaningful transaction-risk cases.

For example, unusual combinations of frequent purchasing activity and low-value transactions could be statistically rare without being inherently suspicious.

A refined behavioural model was therefore developed using:

- `days_since_previous_order`
- `prior_order_count`
- `amount_vs_customer_avg`
- `OnlineOrderFlag`

Absolute transaction value and historical average value are removed from this second model to reduce the influence of customer spending level.

The refined model therefore focuses more directly on:

- transaction timing;
- purchasing frequency;
- customer-specific spending deviation; and
- transaction channel.

The same Isolation Forest configuration is retained:

- 300 estimators
- automatic contamination
- random state = 42

The resulting output is stored as:

- `behaviour_anomaly_score`
- `behaviour_anomaly_percentile`
- `behaviour_top_1pct`
- `behaviour_top_5pct`
- `behaviour_top_10pct`

---

## 12. Cross-Method Validation

The rule-based framework and Isolation Forest models are intentionally developed independently.

This allows the analysis to test whether transactions identified through transparent behavioural rules are also considered statistically unusual by an unsupervised model.

The analysis shows strong convergence between the two approaches.

For the initial Isolation Forest:

- all 10 High-risk rule-based transactions fall within the model's top 10% anomalies;
- 8 of the 10 fall within the top 5%;
- 2 fall within the top 1%.

The refined behaviour-focused model produces even stronger alignment:

- all 10 High-risk transactions fall within the top 5% of behavioural anomalies;
- 3 of the 10 fall within the top 1%.

This provides independent evidence that the highest-priority rule-based cases also exhibit unusual multivariate behavioural patterns.

---

## 13. Model-Only Anomalies

The anomaly model also identifies transactions classified as Low risk by the rule-based framework but appearing within the most statistically unusual transactions.

These cases are retained because multivariate anomaly detection can identify unusual combinations of behaviours that may not exceed any individual rule threshold.

However, statistical abnormality is not interpreted as fraud.

These transactions are treated as additional investigation candidates rather than automatically reclassified as High risk.

---

## 14. Investigation Prioritisation

The final investigation workflow combines interpretable rules with statistical anomaly ranking.

The primary investigation fields include:

- Risk Score
- Risk Level
- Risk Reason
- Anomaly Percentile
- Customer ID
- Order ID
- Order Value
- Days Since Previous Order

The Tableau Investigation Queue allows transactions to be filtered by Risk Score and Risk Reason and reviewed alongside their anomaly ranking.

This creates a layered prioritisation framework:

**Rule-based indicators → Risk Score → Risk Level → Behavioural anomaly ranking → Investigation Queue**

The rule-based framework explains **why** a transaction is considered risky.

The anomaly model provides an independent indication of **how unusual** the transaction's overall behavioural profile is.

Together, the two approaches provide a more complete investigation signal than either method used independently.

---

## 15. Methodological Limitations

The source data does not contain confirmed fraud outcomes.

Therefore:

- Risk Level should not be interpreted as confirmed fraud probability.
- Isolation Forest anomalies should not be interpreted as fraudulent transactions.
- The framework cannot currently be evaluated using supervised classification metrics such as precision, recall or ROC-AUC.
- Risk thresholds are analytical investigation rules rather than empirically validated fraud probabilities.

The current framework should therefore be understood as an **investigation prioritisation system**.

With confirmed fraud labels, future development could include supervised model validation, threshold optimisation and false-positive analysis.
