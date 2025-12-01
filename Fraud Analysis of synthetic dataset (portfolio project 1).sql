CREATE TABLE transactions (
    transaction_id      TEXT PRIMARY KEY,
    user_id             TEXT,
    amount              NUMERIC(14,6),
    transaction_type    TEXT,
    merchant_category   TEXT,
    country             TEXT,
    hour                SMALLINT,
    device_risk_score   REAL,
    ip_risk_score       REAL,
    is_fraud            BOOLEAN
);
SELECT * FROM transactions LIMIT 10;

SELECT *, COUNT(*)
FROM transactions
GROUP BY transaction_id, user_id, amount, transaction_type,
         merchant_category, country, hour, device_risk_score,
         ip_risk_score, is_fraud
HAVING COUNT(*) > 1;

SELECT *
FROM transactions
WHERE transaction_id IS NULL
   OR user_id IS NULL
   OR amount IS NULL
   OR transaction_type IS NULL
   OR merchant_category IS NULL
   OR country IS NULL
   OR hour IS NULL
   OR device_risk_score IS NULL
   OR ip_risk_score IS NULL
   OR is_fraud IS NULL;

--Buisness Questions And Answers::

--What is the overall fraud rate in the dataset?

SELECT 
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) AS fraud_transactions,
    ROUND( (SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END)::numeric 
            / COUNT(*)) * 100, 2) AS fraud_rate_percent
FROM transactions;

--What is the total financial loss caused by fraudulent transactions?

SELECT 
   SUM(amount) AS fraud_loss
FROM transactions
WHERE is_fraud = TRUE;

--Which merchant categories have the highest number of fraudulent transactions?

SELECT 
    merchant_category,
	COUNT(*) AS Fraud_Transactions
FROM transactions
WHERE is_fraud = TRUE
GROUP BY merchant_category
ORDER BY Fraud_Transactions DESC;

--Which merchant categories contribute the most to fraud loss?

SELECT 
  merchant_category,
  SUM(amount) AS Fraud_Loss
FROM transactions 
WHERE is_fraud = TRUE
GROUP BY merchant_category
ORDER BY Fraud_Loss DESC;

--Which transaction types have the highest fraud rate?

SELECT
   transaction_type,
   COUNT(*) AS Total_Transactions,
   SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) AS fraud_transactions,
    ROUND(
        SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END)::decimal 
        / COUNT(*) * 100, 
        2
    ) AS fraud_rate_percent
FROM transactions
GROUP BY  transaction_type
ORDER BY fraud_rate_percent DESC;

--Which transaction types cause the highest fraud loss?

SELECT 
    transaction_type,
	SUM(amount) AS Fraud_Loss
FROM transactions
WHERE is_fraud = TRUE
GROUP BY transaction_type
ORDER BY Fraud_Loss DESC;

--Which countries are most frequently involved in fraudulent transactions?

SELECT 
   country,
   COUNT(*) AS fraud_transactions
FROM transactions
WHERE is_fraud = TRUE 
GROUP BY country
ORDER BY fraud_transactions DESC;

--Which countries have the highest fraud-related financial loss?

SELECT 
   country,
   SUM(amount) AS Fraud_Loss_Amount
FROM transactions
WHERE is_fraud = TRUE
GROUP BY country
ORDER BY Fraud_Loss_Amount DESC;

--How does fraud vary across different IP-Risk Score ranges?

WITH ip_buckets AS (
    SELECT 
        *,
        CASE 
            WHEN ip_risk_score < 0.75 THEN '0-0.75'
            WHEN ip_risk_score < 0.85 THEN '0.75-0.85'
            WHEN ip_risk_score < 0.90 THEN '0.85-0.90'
            WHEN ip_risk_score < 0.95 THEN '0.90-0.95'
            ELSE '0.95-1.0'
        END AS ip_bucket
    FROM transactions
)
SELECT 
    ip_bucket,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) AS fraud_transactions,
    ROUND(
        SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END)::decimal 
        / COUNT(*) * 100, 
        2
    ) AS fraud_rate_percent
FROM ip_buckets
GROUP BY ip_bucket
ORDER BY ip_bucket;

--What percentage of high IP-Risk Score transactions result in fraud?

SELECT 
    ROUND(
        (SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END)::decimal 
        / COUNT(*)) * 100, 
        2
    ) AS high_ip_fraud_percentage
FROM transactions
WHERE ip_risk_score > 0.75;

--Which attribute combinations form repeated suspicious fraud patterns?

WITH fraud AS (
  SELECT
    country,
    merchant_category,
    transaction_type,
    CASE
      WHEN ip_risk_score < 0.75 THEN '0-0.75'
      WHEN ip_risk_score < 0.85 THEN '0.75-0.85'
      WHEN ip_risk_score < 0.90 THEN '0.85-0.90'
      WHEN ip_risk_score < 0.95 THEN '0.90-0.95'
      ELSE '0.95-1.0'
    END AS ip_bucket,
    amount
  FROM transactions
  WHERE is_fraud = TRUE
)
SELECT
  country,
  merchant_category,
  transaction_type,
  ip_bucket,
  COUNT(*)    AS fraud_count,
  SUM(amount) AS fraud_loss,
  ROUND( (COUNT(*)::decimal / (SELECT COUNT(*) FROM transactions WHERE is_fraud = TRUE)) * 100, 2) AS pct_of_all_frauds
FROM fraud
GROUP BY country, merchant_category, transaction_type, ip_bucket
HAVING COUNT(*) >= 3
ORDER BY fraud_count DESC, fraud_loss DESC;

--Which users show repeated high-risk or fraudulent behavior?

SELECT 
    user_id,
    COUNT(*) AS fraud_count,
    SUM(amount) AS fraud_loss,
    AVG(ip_risk_score) AS avg_ip_risk,
    AVG(device_risk_score) AS avg_device_risk
FROM transactions
WHERE is_fraud = TRUE
GROUP BY user_id
HAVING COUNT(*) >= 3
ORDER BY fraud_count DESC, fraud_loss DESC;









