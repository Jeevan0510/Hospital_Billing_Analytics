-- Gold layer: business requirements BR-01..BR-06 over cleaned hospital billing data

-- BR-01 Monthly revenue
CREATE OR REFRESH MATERIALIZED VIEW hospital_billing.default.gold_monthly_billing AS
SELECT
  DATE_TRUNC('month', visit_date)                         AS billing_month,
  CAST(SUM(total_amount) AS DECIMAL(14,2))                AS total_revenue,
  CAST(SUM(insurance_amount) AS DECIMAL(14,2))            AS insurance_amount,
  COUNT(DISTINCT visit_id)                                AS visits
FROM hospital_billing.default.silver_billing_clean
GROUP BY ALL;

-- BR-02 Department performance
CREATE OR REFRESH MATERIALIZED VIEW hospital_billing.default.gold_department_performance AS
SELECT
  department,
  CAST(SUM(total_amount) AS DECIMAL(14,2))                AS total_revenue,
  COUNT(DISTINCT visit_id)                                AS visits,
  CAST(SUM(total_amount) / NULLIF(COUNT(DISTINCT visit_id), 0) AS DECIMAL(14,2)) AS avg_revenue_per_visit
FROM hospital_billing.default.silver_billing_clean
GROUP BY ALL;

-- BR-03 Branch performance
CREATE OR REFRESH MATERIALIZED VIEW hospital_billing.default.gold_branch_performance AS
SELECT
  region,
  city,
  hospital_branch,
  CAST(SUM(total_amount) AS DECIMAL(14,2))                AS total_revenue,
  COUNT(DISTINCT visit_id)                                AS visits
FROM hospital_billing.default.silver_billing_clean
GROUP BY ALL;

-- BR-04 Payer analysis
CREATE OR REFRESH MATERIALIZED VIEW hospital_billing.default.gold_payer_analysis AS
SELECT
  payer_type,
  CAST(SUM(total_amount) AS DECIMAL(14,2))                AS total_revenue,
  CAST(SUM(insurance_amount) AS DECIMAL(14,2))            AS insurance_amount,
  CAST(SUM(CASE WHEN payment_status = 'Pending'
                THEN total_amount ELSE 0 END) AS DECIMAL(14,2)) AS pending_amount
FROM hospital_billing.default.silver_billing_clean
GROUP BY ALL;

-- BR-05 Data-quality visibility
CREATE OR REFRESH MATERIALIZED VIEW hospital_billing.default.gold_data_quality AS
SELECT 'Duplicate rows removed' AS problem,
       (SELECT COUNT(*) FROM hospital_billing.default.bronze_hospital_billing)
         - (SELECT COUNT(*) FROM hospital_billing.default.silver_billing_clean)
         - (SELECT COUNT(*) FROM hospital_billing.default.silver_billing_rejected) AS problem_count
UNION ALL
SELECT 'Bad quantity (null or <= 0)', COUNT(*)
FROM hospital_billing.default.bronze_hospital_billing
WHERE quantity IS NULL OR quantity <= 0
UNION ALL
SELECT 'Bad unit price (null or < 0)', COUNT(*)
FROM hospital_billing.default.bronze_hospital_billing
WHERE unit_price IS NULL OR unit_price < 0
UNION ALL
SELECT 'Blank department', COUNT(*)
FROM hospital_billing.default.bronze_hospital_billing
WHERE department IS NULL OR TRIM(department) = '';

-- BR-06 Reconciliation: Bronze rows = clean rows + rejected rows + duplicates removed
CREATE OR REFRESH MATERIALIZED VIEW hospital_billing.default.gold_reconciliation AS
SELECT
  (SELECT COUNT(*) FROM hospital_billing.default.bronze_hospital_billing)      AS bronze_rows,
  (SELECT COUNT(*) FROM hospital_billing.default.silver_billing_clean)         AS clean_rows,
  (SELECT COUNT(*) FROM hospital_billing.default.silver_billing_rejected)      AS rejected_rows,
  (SELECT COUNT(*) FROM hospital_billing.default.bronze_hospital_billing)
    - (SELECT COUNT(*) FROM hospital_billing.default.silver_billing_clean)
    - (SELECT COUNT(*) FROM hospital_billing.default.silver_billing_rejected)   AS duplicates_removed,
  ((SELECT COUNT(*) FROM hospital_billing.default.silver_billing_clean)
    + (SELECT COUNT(*) FROM hospital_billing.default.silver_billing_rejected)
    <= (SELECT COUNT(*) FROM hospital_billing.default.bronze_hospital_billing)) AS reconciliation_ok;
